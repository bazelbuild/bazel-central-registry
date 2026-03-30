"""Macro for end-to-end bison integration tests."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def _find_m4(runfiles, label):
    """Find the m4 binary in the runfiles of a bison executable."""
    for file in runfiles:
        if file.basename in ("m4", "m4.exe"):
            return file
    fail("Failed to find m4 binary in runfiles of {}".format(label))

def _bison_gen_impl(ctx):
    bison = ctx.executable.bison
    runfiles = ctx.attr.bison[DefaultInfo].default_runfiles.files.to_list()
    m4 = _find_m4(runfiles, ctx.attr.bison.label)

    env = {
        "BISON_PKGDATADIR": "{}.runfiles/{}/data".format(
            bison.path,
            bison.owner.workspace_name,
        ),
        "M4": "{}.runfiles/{}".format(
            bison.path,
            m4.short_path[len("../"):],
        ),
    }

    args = ctx.actions.args()
    outputs = list(ctx.outputs.outs)
    src_out = outputs[0]

    if len(outputs) > 1:
        args.add(outputs[1], format = "--header=%s")

    args.add("-o", src_out)
    args.add(ctx.file.src)

    ctx.actions.run(
        executable = bison,
        arguments = [args],
        inputs = [ctx.file.src],
        outputs = outputs,
        mnemonic = "BisonTestGen",
        env = env,
    )

    return [DefaultInfo(files = depset(outputs))]

_bison_gen = rule(
    implementation = _bison_gen_impl,
    attrs = {
        "bison": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "outs": attr.output_list(
            mandatory = True,
        ),
        "src": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
    },
)

def bison_test(
        *,
        name,
        src,
        header = None,
        bison = Label("//:bison"),
        copts = [],
        linkopts = [],
        deps = [],
        **kwargs):
    """Runs bison on a .y grammar, compiles the generated C, and runs it as a cc_test.

    Creates two targets:
      - `<name>_gen`: a rule that invokes bison to produce C source (and
        optionally a header) from the grammar.
      - `<name>`: a cc_test that compiles and executes the generated code.

    Uses ctx.actions.run with explicit BISON_PKGDATADIR and M4 environment
    variables so bison can locate its data files and m4 on all platforms
    (including Windows) without relying on runfiles self-discovery.

    The .y file must contain an embedded main() and lexer so the generated C is
    self-contained. Grammars that accept empty input (e.g. `input: %empty`)
    will exit 0 when cc_test provides no stdin.

    Args:
        name: Name of the cc_test target.
        src: Label of the .y grammar file to process.
        header: Filename for the generated header (e.g. "calc.h"). Must match
            the grammar's %define api.header.include value. If None, no header
            is generated.
        bison: Label of the bison binary to use.
        copts: Additional C compiler options for the generated code.
        linkopts: Additional linker options (e.g. ["-lm"] for math).
        deps: Additional cc_library deps for the generated code.
        **kwargs: Forwarded to cc_test.
    """
    outs = [name + ".c"]
    if header:
        outs.append(header)

    _bison_gen(
        name = name + "_gen",
        src = src,
        bison = bison,
        outs = outs,
        testonly = True,
    )

    cc_test(
        name = name,
        srcs = [":" + name + "_gen"],
        copts = copts,
        linkopts = linkopts,
        deps = deps,
        **kwargs
    )
