"""gawk_builtin_extension"""

load("@rules_cc//cc:defs.bzl", "cc_library", "cc_shared_library")

# Public headers each extension needs to compile against.
DEFAULT_EXTENSION_DEPS = [
    Label("//:gawkapi"),
    Label("//:gettext"),
]

# Private — `config.h` and `HAVE_CONFIG_H` stay scoped to each extension's own
# compile so the produced `.so` doesn't leak them through transitive headers.
DEFAULT_EXTENSION_IMPL_DEPS = [
    Label("//extension:config"),
]

SHARED_LIB_EXTENSION = select({
    "@platforms//os:windows": ".dll",
    "//conditions:default": ".so",
})

# Every upstream gawk extension `#include`s POSIX-only headers (`unistd.h`,
# `dirent.h`, ...). MinGW ships those, MSVC doesn't — and upstream gawk
# itself never supported MSVC builds — so mark each extension target
# incompatible there. Wildcard builds (`@gawk//...`) under MSVC will skip
# the extensions instead of failing.
_INCOMPATIBLE_WITH_MSVC = select({
    "@rules_cc//cc/compiler:msvc-cl": ["@platforms//:incompatible"],
    "//conditions:default": [],
})

# Silence all warnings in the (upstream) extension sources — they're
# not code we maintain, so warnings would only add noise. Mirrors
# `GAWK_COPTS` in the root BUILD: `/w` on MSVC-style frontends
# (`msvc-cl`, `clang-cl`); `-w` everywhere else (gcc, clang,
# mingw-gcc, emscripten, …).
_EXTENSION_COPTS = select({
    "@rules_cc//cc/compiler:clang-cl": ["/w"],
    "@rules_cc//cc/compiler:msvc-cl": ["/w"],
    "//conditions:default": ["-w"],
})

def gawk_builtin_extension(
        *,
        name,
        srcs,
        extra_deps = [],
        visibility = []):
    """Macro for declaring a built-in gawk extension library.

    The result is a `cc_shared_library` target which provides the dynamic library artifact.

    This is only intended for use in the `//extension` package.
    """
    lib_name = name + "_lib"
    cc_library(
        name = lib_name,
        srcs = srcs,
        copts = _EXTENSION_COPTS,
        includes = ["."],
        local_defines = ["HAVE_CONFIG_H"],
        target_compatible_with = _INCOMPATIBLE_WITH_MSVC,
        deps = DEFAULT_EXTENSION_DEPS + extra_deps,
        implementation_deps = DEFAULT_EXTENSION_IMPL_DEPS,
    )

    cc_shared_library(
        name = name,
        shared_lib_name = name + SHARED_LIB_EXTENSION,
        target_compatible_with = _INCOMPATIBLE_WITH_MSVC,
        deps = [lib_name],
        visibility = visibility,
    )
