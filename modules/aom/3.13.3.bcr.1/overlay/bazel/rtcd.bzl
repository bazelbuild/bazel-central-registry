"""RTCD (Runtime CPU Detection) header generation rule for libaom.

Runs build/cmake/rtcd.pl (wrapped as a perl_binary) to produce RTCD
dispatch headers.
"""

def _rtcd_gen_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)

    # On Windows, perl_binary produces a .bat wrapper.  cmd.exe (used
    # internally to run .bat files) misinterprets forward-slash path
    # separators as option prefixes, so normalise to backslashes.
    script_path = ctx.executable.rtcd_script.path
    if script_path.endswith(".bat") or script_path.endswith(".cmd"):
        script_path = script_path.replace("/", "\\")

    args = ctx.actions.args()
    args.add(out)
    args.add("--")
    args.add(script_path)
    args.add(ctx.attr.arch, format = "--arch=%s")
    args.add(ctx.attr.sym, format = "--sym=%s")
    args.add(ctx.file.config, format = "--config=%s")
    args.add_all(ctx.attr.disable, format_each = "--disable-%s")
    args.add(ctx.file.defs)

    ctx.actions.run(
        executable = ctx.executable._stdout_to_file,
        arguments = [args],
        inputs = [ctx.file.config, ctx.file.defs],
        outputs = [out],
        tools = [ctx.executable.rtcd_script],
        mnemonic = "AomRtcdGen",
    )
    return [DefaultInfo(files = depset([out]))]

rtcd_gen = rule(
    implementation = _rtcd_gen_impl,
    doc = "Generate RTCD dispatch header from a perlasm definition file.",
    attrs = {
        "arch": attr.string(
            mandatory = True,
            doc = "Target architecture for RTCD (x86_64 or arm64).",
        ),
        "config": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The aom_config.h file.",
        ),
        "defs": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The RTCD definitions file (.pl).",
        ),
        "disable": attr.string_list(
            default = [],
            doc = "List of extensions to disable (e.g. ['sve', 'sve2']).",
        ),
        "out": attr.string(
            mandatory = True,
            doc = "Output header file path.",
        ),
        "rtcd_script": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            doc = "The rtcd.pl perl_binary target.",
        ),
        "sym": attr.string(
            mandatory = True,
            doc = "Symbol prefix for the RTCD functions (e.g. aom_dsp_rtcd).",
        ),
        "_stdout_to_file": attr.label(
            default = Label("//bazel:stdout_to_file"),
            executable = True,
            cfg = "exec",
        ),
    },
)
