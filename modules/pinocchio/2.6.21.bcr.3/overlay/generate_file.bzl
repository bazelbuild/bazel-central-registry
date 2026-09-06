load("@bazel_skylib//lib:shell.bzl", "shell")

def _generate_file_impl(ctx):
    """Rule for generating custom files from templates."""

    output = ctx.actions.declare_file(ctx.attr.out)

    sanitized_library_name = shell.quote(ctx.attr.library_name).replace("'", "").upper()
    derived_export_symbol = sanitized_library_name + "_EXPORTS"
    version_parts = ctx.attr.library_version.split(".")
    if len(version_parts) < 3:
        fail("Version string '{}' is not in the expected 'major.minor.patch' format.".format(ctx.attr.library_version))

    substitutions = {
        "@LIBRARY_NAME@": sanitized_library_name,
        "@PACKAGE_CPPNAME@": sanitized_library_name,
        "@PROJECT_VERSION@": ctx.attr.library_version,
        "@PROJECT_VERSION_MAJOR_CONFIG@": version_parts[0],
        "@PROJECT_VERSION_MINOR_CONFIG@": version_parts[1],
        "@PROJECT_VERSION_PATCH_CONFIG@": version_parts[2],
        "@EXPORT_SYMBOL@": derived_export_symbol,
    }

    ctx.actions.expand_template(
        output = output,
        template = ctx.file.template,
        substitutions = substitutions,
    )
    return [DefaultInfo(files = depset([output]))]

generate_file = rule(
    implementation = _generate_file_impl,
    attrs = {
        "template": attr.label(
            doc = "The template base file used for generation.",
            allow_single_file = True,
            mandatory = True,
        ),
        "out": attr.string(
            doc = "The path and name of the output file.",
            mandatory = True,
        ),
        "library_name": attr.string(
            doc = "The base name of the library, used for macro prefixes.",
            mandatory = True,
        ),
        "library_version": attr.string(
            doc = "The full project version string (e.g., '1.2.3').",
            mandatory = True,
        ),
    },
)
