"""fidelity_test: checks a Bazel-generated file against the upstream script it replaces.

Consumers build the Bazel target, which needs no host tools. This test, run only in this repository, executes the
unmodified upstream script in a build action and compares the two with skylib's diff_test, so the Starlark port cannot
drift from the upstream contract. Both sides build through the same platform transition, so a `settings` value reaches
the script's inputs and the target alike.
"""

load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("//tools:transition.bzl", "CPU", "PLATFORM", "platform_constraints_transition", "transition_default_constraints")

_COREUTILS = "@bazel_lib//lib:coreutils_toolchain_type"

def _upstream_output_impl(ctx):
    coreutils = ctx.toolchains[_COREUTILS].coreutils_info.bin
    tools = []
    for name, tool in {
        "awk": ctx.executable._awk,
        "cat": coreutils,
        "cp": coreutils,
        "grep": ctx.executable._grep,
        "mkdir": coreutils,
        "sed": ctx.executable._sed,
        "tr": coreutils,
    }.items():
        link = ctx.actions.declare_file("{}.path/{}".format(ctx.label.name, name))
        ctx.actions.symlink(output = link, target_file = tool, is_executable = True)
        tools.append(link)

    objroot = "{}.objroot".format(ctx.label.name)
    staged = []
    for src in ctx.files.srcs:
        link = ctx.actions.declare_file("{}/{}".format(objroot, src.short_path))
        ctx.actions.symlink(output = link, target_file = src)
        staged.append(link)

    # A registry overlay delivers files without their executable bit on Bazel 7, so run an executable copy.
    script = ctx.actions.declare_file("{}.script/{}".format(ctx.label.name, ctx.file.script.basename))
    ctx.actions.expand_template(template = ctx.file.script, output = script, substitutions = {}, is_executable = True)

    output = ctx.actions.declare_file(ctx.label.name + ".out")
    ctx.actions.run_shell(
        mnemonic = "FidelityScript",
        inputs = [script] + tools + staged,
        outputs = [output],
        command = 'script="$PWD/$1" out="$PWD/$2" && export PATH="$PWD/$3" && cd "$4" && eval "$5" && shift 5 && "$script" "$@" > "$out"',
        arguments = [
            script.path,
            output.path,
            tools[0].dirname,
            "/".join([ctx.bin_dir.path, ctx.label.package, objroot]),
            ctx.attr.setup,
        ] + ctx.attr.script_args,
    )
    return [DefaultInfo(files = depset([output]))]

_upstream_output = rule(
    doc = "What upstream's `script` writes to stdout from `srcs`. PATH holds only awk (gawk), cat, cp, mkdir and tr " +
          "(uutils coreutils), grep and sed (GNU); /bin/sh is the host's.",
    implementation = _upstream_output_impl,
    attrs = {
        "cpu": attr.string(doc = "Read by the transition; see transition_default_constraints.", mandatory = True),
        "platform": attr.string(
            doc = "Read by the transition; see transition_default_constraints.",
            mandatory = True,
        ),
        "script": attr.label(
            doc = "The upstream generator script, executed directly so its shebang applies.",
            allow_single_file = True,
            mandatory = True,
        ),
        "script_args": attr.string_list(
            doc = "configure's invocation of `script` with `${objroot}` empty; it runs from the objroot.",
        ),
        "settings": attr.label_keyed_string_dict(
            doc = "Read by the transition; see transition_default_constraints.",
        ),
        "setup": attr.string(
            doc = "Shell commands run first in the objroot with the same PATH, for upstream recipe steps before `script`.",
        ),
        "srcs": attr.label_list(
            doc = "Inputs, staged in the objroot at their paths relative to the module root.",
            allow_files = True,
            cfg = platform_constraints_transition,
        ),
        "_awk": attr.label(
            default = Label("@gawk//:gawk"),
            cfg = "exec",
            executable = True,
        ),
        "_grep": attr.label(
            default = Label("@grep//:grep"),
            cfg = "exec",
            executable = True,
        ),
        "_sed": attr.label(
            default = Label("@sed//:sed"),
            cfg = "exec",
            executable = True,
        ),
    },
    toolchains = [_COREUTILS],
)

def fidelity_test(name, generated, srcs = [], script = None, script_args = [], setup = "", settings = {}, size = "small"):
    """Compares `generated` with what upstream's `script` writes to stdout from the same `srcs`.

    Both build through the platform transition with `settings`.

    Args:
      name: The diff_test's name; the helper targets are `<name>.upstream` and `<name>.generated`.
      generated: The Bazel target whose single output is checked.
      srcs: Inputs, staged at their paths relative to the module root.
      script: The upstream generator script.
      script_args: configure's invocation of `script` with `${objroot}` empty.
      setup: Shell commands run first, for upstream recipe steps before `script`.
      settings: Settings to transition to; see transition_default_constraints.
      size: The test size.
    """
    upstream = name + ".upstream"
    generated_out = name + ".generated"

    _upstream_output(
        name = upstream,
        testonly = True,
        srcs = srcs,
        cpu = CPU,
        platform = PLATFORM,
        script = script,
        script_args = script_args,
        settings = settings,
        setup = setup,
        tags = ["manual"],
    )

    transition_default_constraints(
        name = generated_out,
        testonly = True,
        src = generated,
        cpu = CPU,
        platform = PLATFORM,
        settings = settings,
        tags = ["manual"],
    )

    diff_test(
        name = name,
        size = size,
        file1 = ":" + upstream,
        file2 = ":" + generated_out,
    )

def private_namespace_fidelity_test(name, namespace, sym_prefix, settings = {}):
    """Compares a private_namespace target with upstream's private_symbols.sh, awk and private_namespace.sh.

    The upstream side runs over the target's `nm` listing (`<namespace>.nm`, generated or checked in) and its
    export_syms, both from its `upstream_inputs` output group.

    Args:
      name: The test's name.
      namespace: The private_namespace target.
      sym_prefix: configure's SYM_PREFIX; may be a select.
      settings: Settings to transition to; see transition_default_constraints.
    """
    label = native.package_relative_label(namespace)
    stem = label.package + "/" + label.name
    inputs = label.name + "_upstream_inputs"
    native.filegroup(
        name = inputs,
        testonly = True,
        srcs = [label],
        output_group = "upstream_inputs",
        tags = ["manual"],
    )
    fidelity_test(
        name = name,
        srcs = [
            "//include/jemalloc/internal:private_symbols.sh",
            ":" + inputs,
        ],
        generated = label,
        script = "//include/jemalloc/internal:private_namespace.sh",
        script_args = [label.name + ".sym"],
        settings = settings,
        setup = ("include/jemalloc/internal/private_symbols.sh \"" + sym_prefix + "\" `cat " + stem + ".export_syms` > " + label.name + ".awk && " +
                 "awk -f " + label.name + ".awk " + stem + ".nm > " + label.name + ".sym"),
    )
