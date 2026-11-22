"""Fills in upstream's CMake test templates (configure_file in tests/CMakeLists.txt)."""

def _configure_file_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".cpp")
    ctx.actions.expand_template(
        template = ctx.file.src,
        output = out,
        substitutions = ctx.attr.substitutions,
    )
    return [DefaultInfo(files = depset([out]))]

configure_file = rule(
    implementation = _configure_file_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
        "substitutions": attr.string_dict(),
    },
)
