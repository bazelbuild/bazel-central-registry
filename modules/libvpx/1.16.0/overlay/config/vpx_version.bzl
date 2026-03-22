"""Generates vpx_version.h from a version string."""

def _emit_file_impl(ctx):
    ctx.actions.write(output = ctx.outputs.out, content = ctx.attr.content)

_emit_file = rule(
    implementation = _emit_file_impl,
    attrs = {
        "content": attr.string(mandatory = True),
        "out": attr.output(mandatory = True),
    },
)

def vpx_version_header(name, version, out):
    """Generates vpx_version.h from a semantic version string.

    Args:
        name: Rule name.
        version: Version string in "major.minor.patch" format.
        out: Output file path for vpx_version.h.
    """
    parts = version.split(".")
    if len(parts) != 3:
        fail("Version must be in major.minor.patch format, got: %s" % version)
    major = parts[0]
    minor = parts[1]
    patch = parts[2]

    content = "\n".join([
        "// This file is generated. Do not edit.",
        "#ifndef VPX_VERSION_H_",
        "#define VPX_VERSION_H_",
        "#define VERSION_MAJOR  %s" % major,
        "#define VERSION_MINOR  %s" % minor,
        "#define VERSION_PATCH  %s" % patch,
        '#define VERSION_EXTRA  ""',
        "#define VERSION_PACKED ((VERSION_MAJOR<<16)|(VERSION_MINOR<<8)|(VERSION_PATCH))",
        '#define VERSION_STRING_NOSP "v%s"' % version,
        '#define VERSION_STRING      " v%s"' % version,
        "#endif  // VPX_VERSION_H_",
        "",
    ])

    _emit_file(
        name = name,
        out = out,
        content = content,
    )
