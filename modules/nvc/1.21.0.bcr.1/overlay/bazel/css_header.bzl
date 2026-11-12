"""Custom rule that wraps `bazel/tools/css_to_header.sh`."""

def _css_header_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    args = ctx.actions.args()
    args.add("--in", ctx.file.src)
    args.add("--out", out)
    args.add("--varname", ctx.attr.varname)
    ctx.actions.run(
        executable = ctx.executable._tool,
        arguments = [args],
        inputs = [ctx.file.src],
        outputs = [out],
        mnemonic = "NvcCssToHeader",
        progress_message = "Generating C header from %s" % ctx.file.src.short_path,
    )
    return [DefaultInfo(files = depset([out]))]

css_header = rule(
    implementation = _css_header_impl,
    doc = """\
Used to generate `src/cov/cov-style.h` from `src/cov/cov-style.css`
(the upstream `Makemodule.am` does the same job with an inline `sed`
pipeline). Implemented as a real rule rather than a `genrule` so the
underlying process wrapper has a typed, named-argument CLI instead of
a free-form shell command.
""",
    attrs = {
        "out": attr.string(
            doc = "Output header file (declared as a generated file).",
            mandatory = True,
        ),
        "src": attr.label(
            doc = "Input CSS file.",
            allow_single_file = True,
            mandatory = True,
        ),
        "varname": attr.string(
            doc = "Name of the C `const char[]` to define.",
            mandatory = True,
        ),
        "_tool": attr.label(
            default = Label("//bazel:css_to_header"),
            executable = True,
            cfg = "exec",
        ),
    },
)
