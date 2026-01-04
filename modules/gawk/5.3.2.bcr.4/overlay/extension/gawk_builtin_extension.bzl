"""
Macro for declaring a built-in gawk extension library.

The result is a `cc_shared_library` target which provides the dynamic library artifact.

This is only intended for use in the `//extension` package.
"""

load("@rules_cc//cc:defs.bzl", "cc_library", "cc_shared_library")

DEFAULT_EXTENSION_DEPS = [
    "//:gawkapi",
    "//:gettext",
    "//extension:config",
]

SHARED_LIB_EXTENSION = select({
    "@platforms//os:windows": ".dll",
    "//conditions:default": ".so",
})

def gawk_builtin_extension(name, srcs, extra_deps = [], visibility = []):
    lib_name = name + "_lib"
    cc_library(
        name = lib_name,
        srcs = srcs,
        includes = ["."],
        deps = DEFAULT_EXTENSION_DEPS + extra_deps,
    )

    cc_shared_library(
        name = name,
        shared_lib_name = name + SHARED_LIB_EXTENSION,
        deps = [lib_name],
        visibility = visibility,
    )
