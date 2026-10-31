"""Generate ngspice configuration without executing configuration tools."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

def _config_header_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = ctx.outputs.out,
        substitutions = {
            "@XSPICE@": "#define XSPICE 1\n#define IPC_UNIX_SOCKETS 1" if ctx.attr.xspice else "/* XSPICE is disabled. */",
            "@OPENMP@": "#define USE_OMP 1" if ctx.attr.openmp else "#define HAVE_GETRUSAGE 1\n#define HAVE_TIMES 1",
        },
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

_config_header = rule(
    implementation = _config_header_impl,
    attrs = {
        "openmp": attr.bool(mandatory = True),
        "out": attr.output(mandatory = True),
        "xspice": attr.bool(mandatory = True),
        "_template": attr.label(
            default = Label("//private:config.h.in"),
            allow_single_file = True,
        ),
    },
)

def ngspice_config(name):
    """Expose ngspice/config.h as :name, validated by normal C/C++ compilation.

    The template describes the supported GCC/Clang, Linux/macOS POSIX contract.
    Optional SDK headers are detected by the target compiler's preprocessor.
    Root settings :with_xspice and :with_openmp select optional features.
    SHARED_MODULE remains a local define on separately compiled API targets.

    Args:
        name: Name of the configuration cc_library, normally "config".
    """
    compatible = select({
        "@platforms//os:linux": [],
        "@platforms//os:macos": [],
        "//conditions:default": ["@platforms//:incompatible"],
    })
    _config_header(
        name = name + "_header",
        out = name + "/ngspice/config.h",
        openmp = select({
            ":with_openmp": True,
            "//conditions:default": False,
        }),
        xspice = select({
            ":with_xspice": True,
            "//conditions:default": False,
        }),
        target_compatible_with = compatible,
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = name,
        hdrs = [":" + name + "_header"],
        # Several upstream sources include system headers before config.h.
        # Set this on their command line so GNU declarations are visible even
        # in those translation units. The public API linking-only boundary keeps this private.
        defines = ["_GNU_SOURCE"],
        strip_include_prefix = name,
        target_compatible_with = compatible,
        visibility = ["//visibility:private"],
    )
