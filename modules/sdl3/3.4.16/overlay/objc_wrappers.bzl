"""This file gives a rule that wraps Objective-C sources for cc_library."""

visibility("private")

def _src_path(src):
    """Returns the path of the source from the repository root."""
    label = src.owner
    return label.package + "/" + label.name if label.package else label.name

def _objc_wrappers_impl(ctx):
    outputs = []
    for src in ctx.files.srcs:
        path = _src_path(src)
        wrapper = ctx.actions.declare_file(ctx.attr.prefix + "/" + path + ".c")
        ctx.actions.write(wrapper, "#include \"%s\"\n" % path)
        outputs.append(wrapper)
    return [DefaultInfo(files = depset(outputs))]

objc_wrappers = rule(
    implementation = _objc_wrappers_impl,
    attrs = {
        "prefix": attr.string(
            default = "objc",
            doc = "Directory the generated files go in.",
        ),
        "srcs": attr.label_list(
            allow_files = [".m"],
            doc = "Objective-C sources to wrap.",
        ),
    },
    doc = """\
This rule writes one C file for each source. Each C file includes its source
by the path from the repository root. A cc_library compiles those C files with
`-x objective-c`, so any C toolchain that targets macOS can build them.
objc_library accepts `.m` files directly, but works only with apple_support's
toolchain. `__FILE__` and the debug line table still name the `.m` file.
""",
)
