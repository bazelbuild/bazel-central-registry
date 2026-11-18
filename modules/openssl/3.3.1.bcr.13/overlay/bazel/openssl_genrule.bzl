"""OpenSSL Perl code generation at build time.

Generates the files OpenSSL's own build generates: util/dofile.pl templates
(.h.in, .c.in, .inc.in), stdout generator scripts (util/mkerr.pl and the
crypto/* table scripts on 4.1+), progs.pl and mkbuildinf.pl. Template
processing is batched into a single Perl invocation via batch_dofile to avoid
per-template process-creation overhead on Windows; everything else is one
redirect_stdout action per output.

The file lists are not hardcoded here: they are generated into
//bazel/constants:templates.bzl from OpenSSL's configdata.pm, so they track
whatever OpenSSL version the overlay was generated for.
"""

load("//bazel/constants:generated_srcs.bzl", "COMMON_GENERATED_CRYPTO_SRCS", "GENERATED_CRYPTO_EXTRA_SRCS")
load(
    "//bazel/constants:templates.bzl",
    "DOFILE_HDR_TEMPLATES",
    "DOFILE_SRC_TEMPLATES",
    "HERMETIC_ENV",
    "STDOUT_SCRIPTS",
)

_SRCDIR = "$(SRCDIR)/"
_BLDDIR = "$(BLDDIR)/"

def _is_app_output(path):
    """Generated files under apps/ belong to the openssl binary, not libcrypto."""
    return path.startswith("apps/")

def _run_redirected(ctx, tool, out, args_list, inputs = [], mnemonic = "OpenSSLGenerate"):
    """Run an exec-configured tool via redirect_stdout, capturing its stdout into `out`."""
    args = ctx.actions.args()
    args.add(tool[DefaultInfo].files_to_run.executable)
    args.add(out)
    args.add("--")
    args.add_all(args_list)
    ctx.actions.run(
        executable = ctx.executable._redirect_stdout,
        arguments = [args],
        inputs = inputs,
        outputs = [out],
        tools = [tool[DefaultInfo].files_to_run],
        env = HERMETIC_ENV,
        mnemonic = mnemonic,
        progress_message = "Generating %s" % out.short_path,
        toolchain = None,
    )
    return out

def _run_dofile(ctx):
    """Run batch_dofile once for all templates; returns (libcrypto outputs, apps outputs)."""
    inputs = []
    crypto_outs = []
    app_outs = []
    args = ctx.actions.args()

    # The --in/--out pairs for all templates exceed the Windows cmd.exe
    # command-line limit, so always pass them via a params file, which
    # batch_dofile.pl expands.
    args.use_param_file("@%s", use_always = True)
    args.set_param_file_format("multiline")

    for target, output in ctx.attr.templates_map.items():
        template_file = target.files.to_list()[0]
        out_file = ctx.actions.declare_file(output)
        inputs.append(template_file)
        (app_outs if _is_app_output(output) else crypto_outs).append(out_file)
        args.add("--in=" + template_file.path)
        args.add("--out=" + out_file.path)

    ctx.actions.run(
        executable = ctx.executable._batch_dofile,
        arguments = [args],
        inputs = inputs,
        outputs = crypto_outs + app_outs,
        mnemonic = "OpenSSLDofile",
        progress_message = "Generating %d template files" % (len(crypto_outs) + len(app_outs)),
        toolchain = None,
    )
    return crypto_outs, app_outs

def _run_stdout_scripts(ctx):
    """Run the stdout generators in ctx.attr.script_outputs; returns (libcrypto outputs, apps outputs)."""
    source_files = {f.owner.name: f for f in ctx.files.script_inputs}

    # Declare every output first: one may consume another ($(BLDDIR)/
    # arguments); STDOUT_SCRIPTS is already in dependency order.
    declared = {out_path: ctx.actions.declare_file(out_path) for out_path in ctx.attr.script_outputs}
    for out_path in ctx.attr.script_outputs:
        spec = STDOUT_SCRIPTS[out_path]
        script = source_files.get(spec["script"])
        if script == None:
            fail("Generator script %s for %s is not in script_inputs" % (spec["script"], out_path))
        inputs = [script]
        argv = [script]
        for arg in spec["args"]:
            if arg.startswith(_SRCDIR):
                f = source_files.get(arg[len(_SRCDIR):])
                if f == None:
                    fail("Generator input %s for %s is not in script_inputs" % (arg, out_path))
            elif arg.startswith(_BLDDIR):
                f = declared.get(arg[len(_BLDDIR):])
                if f == None:
                    fail("Generated input %s for %s is not produced by this rule" % (arg, out_path))
            else:
                argv.append(arg)
                continue
            inputs.append(f)
            argv.append(f)
        for dep in spec["deps"]:
            f = source_files.get(dep) or declared.get(dep)
            if f != None and f not in inputs:
                inputs.append(f)
        _run_redirected(ctx, ctx.attr._run_generator, declared[out_path], argv, inputs, "OpenSSLScriptGen")
    crypto_outs = [f for out_path, f in declared.items() if not _is_app_output(out_path)]
    app_outs = [f for out_path, f in declared.items() if _is_app_output(out_path)]
    return crypto_outs, app_outs

def _openssl_gen_impl(ctx):
    crypto_outs, app_outs = _run_dofile(ctx)
    script_crypto, script_app = _run_stdout_scripts(ctx)
    crypto_outs.extend(script_crypto)
    app_outs.extend(script_app)

    if ctx.attr.mode == "hdrs":
        buildinf = ctx.actions.declare_file("crypto/buildinf.h")
        crypto_outs.append(_run_redirected(ctx, ctx.attr._mkbuildinf, buildinf, ["bazel", "bazel"], mnemonic = "OpenSSLBuildinf"))
        progs = ctx.actions.declare_file("apps/progs.h")
        app_outs.append(_run_redirected(ctx, ctx.attr._progs_gen, progs, ["-H", "apps/openssl"], mnemonic = "OpenSSLProgs"))
    else:
        progs = ctx.actions.declare_file("apps/progs.c")
        app_outs.append(_run_redirected(ctx, ctx.attr._progs_gen, progs, ["-C", "apps/openssl"], mnemonic = "OpenSSLProgs"))

    return [
        DefaultInfo(files = depset(crypto_outs)),
        OutputGroupInfo(app = depset(app_outs)),
    ]

_openssl_gen = rule(
    implementation = _openssl_gen_impl,
    doc = """Generates OpenSSL headers or sources at build time.

All tools are exec-configured attributes (perl_binary targets), not toolchains,
so actions pass toolchain = None for --incompatible_auto_exec_groups.

In "hdrs" mode: renders the header templates and header-producing scripts,
crypto/buildinf.h, and apps/progs.h. In "srcs" mode: the source templates and
scripts for the current configuration, and apps/progs.c.

Outputs under apps/ (progs.*, and on 4.1+ apps/include/configuration.h) go
into OutputGroupInfo("app"); everything else into DefaultInfo.""",
    attrs = {
        "mode": attr.string(
            mandatory = True,
            values = ["hdrs", "srcs"],
            doc = "'hdrs' for headers + buildinf + progs.h, 'srcs' for sources + progs.c.",
        ),
        "templates_map": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Map of .in template file labels to their canonical output paths.",
        ),
        "script_outputs": attr.string_list(
            doc = "Outputs of STDOUT_SCRIPTS to produce, in STDOUT_SCRIPTS order.",
        ),
        "script_inputs": attr.label_list(
            allow_files = True,
            doc = "The generator scripts and every source file they read ($(SRCDIR)/ arguments, declared deps).",
        ),
        "_run_generator": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//bazel:run_generator"),
        ),
        "_batch_dofile": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//bazel:batch_dofile"),
        ),
        "_mkbuildinf": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//:mkbuildinf"),
        ),
        "_progs_gen": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//:progs_gen"),
        ),
        "_redirect_stdout": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//bazel:redirect_stdout"),
        ),
    },
)

def _generated_srcs_select(pick):
    """select() over configurations of pick(<generated libcrypto sources for that configuration>).

    Mirrors the libcrypto srcs select in //:BUILD: only the generated sources
    Configure lists for a platform are produced and compiled; the rest (e.g.
    Windows-only providers) are left out exactly as OpenSSL's own build would.
    """
    no_asm = COMMON_GENERATED_CRYPTO_SRCS + GENERATED_CRYPTO_EXTRA_SRCS["no_asm"]
    branches = {
        "//configs:_asm_" + config: pick(COMMON_GENERATED_CRYPTO_SRCS + extra)
        for config, extra in GENERATED_CRYPTO_EXTRA_SRCS.items()
        if config != "no_asm"
    }
    branches["//configs:_no_asm_fallback"] = pick(no_asm)
    branches["//conditions:default"] = pick(no_asm)
    return select(branches)

def _src_templates_for(outputs):
    """Subset of DOFILE_SRC_TEMPLATES (template -> output) producing the given outputs."""
    wanted = {out: None for out in outputs}
    return {tmpl: out for tmpl, out in DOFILE_SRC_TEMPLATES.items() if out in wanted}

def _script_srcs_for(outputs):
    """Subset of STDOUT_SCRIPTS outputs (sources only) among the given outputs, in STDOUT_SCRIPTS order."""
    wanted = {out: None for out in outputs}
    return [out for out in STDOUT_SCRIPTS if out.endswith(".c") and out in wanted]

def _script_inputs():
    """Every file the stdout generators need from the source tree: the scripts, their arguments, their deps."""
    inputs = {}
    for spec in STDOUT_SCRIPTS.values():
        inputs[spec["script"]] = None
        for arg in spec["args"]:
            if arg.startswith(_SRCDIR):
                inputs[arg[len(_SRCDIR):]] = None
        for dep in spec["deps"]:
            if dep not in STDOUT_SCRIPTS:
                inputs[dep] = None
    return inputs.keys()

def openssl_perl_genrule(*, name, mode = None, **kwargs):
    """Generate OpenSSL's build-time generated headers (mode "hdrs") or sources (mode "srcs").

    Args:
        name: Target name.
        mode: "hdrs" or "srcs". If None, inferred from name suffix.
        **kwargs: Additional keyword arguments.
    """
    if mode == None:
        if name.endswith("_hdrs"):
            mode = "hdrs"
        elif name.endswith("_srcs"):
            mode = "srcs"
        else:
            fail("Cannot infer mode from name '{}'; pass mode explicitly".format(name))

    if mode == "hdrs":
        _openssl_gen(
            name = name,
            mode = "hdrs",
            templates_map = DOFILE_HDR_TEMPLATES,
            script_outputs = [out for out in STDOUT_SCRIPTS if not out.endswith(".c")],
            script_inputs = _script_inputs(),
            **kwargs
        )
    elif mode == "srcs":
        _openssl_gen(
            name = name,
            mode = "srcs",
            templates_map = _generated_srcs_select(_src_templates_for),
            script_outputs = _generated_srcs_select(_script_srcs_for),
            script_inputs = _script_inputs(),
            **kwargs
        )
    else:
        fail("mode must be 'hdrs' or 'srcs', got: " + mode)
