"""Rule for generating the version.h file for libsodium."""

VERSION_H_TEMPLATE = "//:src/libsodium/include/sodium/version.h.in"
DEFAULT_VERSION = "1.0.19"
DEFAULT_SODIUM_LIBRARY_VERSION_MAJOR = "26"
DEFAULT_SODIUM_LIBRARY_VERSION_MINOR = "1"
DEFAULT_MINIMAL = True

def _gen_version_hdr_impl(ctx):
    substitutions = {
        "@VERSION@": ctx.attr.version,
        "@SODIUM_LIBRARY_VERSION_MAJOR@": ctx.attr.sodium_library_version_major,
        "@SODIUM_LIBRARY_VERSION_MINOR@": ctx.attr.sodium_library_version_minor,
        # Replace this so we don't have to expose the sodium sub-directory as a public include.
        '#include "export.h"': '#include "sodium/export.h"',
    }
    if ctx.attr.minimal:
        substitutions.update({"@SODIUM_LIBRARY_MINIMAL_DEF@": "#define SODIUM_LIBRARY_MINIMAL 1"})
    else:
        substitutions.update({"@SODIUM_LIBRARY_MINIMAL_DEF@": "#undef SODIUM_LIBRARY_MINIMAL"})
    ctx.actions.expand_template(
        template = ctx.file._template,
        substitutions = substitutions,
        output = ctx.outputs.version_hdr,
    )

gen_version_hdr = rule(
    implementation = _gen_version_hdr_impl,
    attrs = {
        "version": attr.string(default = DEFAULT_VERSION),
        "sodium_library_version_major": attr.string(default = DEFAULT_SODIUM_LIBRARY_VERSION_MAJOR),
        "sodium_library_version_minor": attr.string(default = DEFAULT_SODIUM_LIBRARY_VERSION_MINOR),
        "minimal": attr.bool(default = DEFAULT_MINIMAL),
        "_template": attr.label(
            default = Label(VERSION_H_TEMPLATE),
            allow_single_file = True,
        ),
    },
    outputs = {"version_hdr": "sodium/version.h"},
)
