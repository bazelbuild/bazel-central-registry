"""Rule for generating the version.h file for libsodium."""

VERSION_H_TEMPLATE = "//:src/libsodium/include/sodium/version.h.in"
VERSION_H_OUTPUT_FILE = "sodium/version.h"
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

    version_hdr = ctx.actions.declare_file(VERSION_H_OUTPUT_FILE)
    ctx.actions.expand_template(
        template = ctx.file._template,
        substitutions = substitutions,
        output = version_hdr,
    )
    return [DefaultInfo(files = depset([version_hdr]))]

gen_version_hdr = rule(
    implementation = _gen_version_hdr_impl,
    attrs = {
        "version": attr.string(),
        "sodium_library_version_major": attr.string(),
        "sodium_library_version_minor": attr.string(),
        "minimal": attr.bool(default = DEFAULT_MINIMAL),
        "_template": attr.label(
            default = Label(VERSION_H_TEMPLATE),
            allow_single_file = True,
        ),
    },
)
