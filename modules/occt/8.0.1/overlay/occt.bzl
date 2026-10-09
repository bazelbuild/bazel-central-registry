"""Helpers to build OpenCASCADE (OCCT) from source with plain Bazel C++ rules.

OCCT keeps its sources in src/<Module>/<Toolkit>/<Package>/, but every header is
included by its bare file name (e.g. #include <gp_Pnt.hxx>). The upstream CMake
build therefore copies all headers into a single flat directory; `occt_headers`
does the same with a symlink action per header.
"""

load("@bazel_skylib//lib:selects.bzl", "selects")
load("@rules_cc//cc:defs.bzl", "cc_library")

_HEADER_PATTERNS = [
    "*.hxx",
    "*.lxx",
    "*.gxx",
    "*.pxx",
    "*.h",
]

_SOURCE_PATTERNS = [
    "*.cxx",
    # Only the bundled delabella triangulation library uses this extension.
    "*.cpp",
    "*.c",
]

# Unit tests shipped with the sources; they need GoogleTest and are not part of
# the libraries.
_EXCLUDES = ["**/GTests/**"]

_INCLUDE_DIR = "inc"

_MSVC_STYLE_COMPILERS = (
    "@rules_cc//cc/compiler:clang-cl",
    "@rules_cc//cc/compiler:msvc-cl",
)

_WINDOWS_SYSTEM_LIBS = [
    "advapi32",
    "user32",
    "gdi32",
    "shell32",
    "ole32",
    "oleaut32",
    "ws2_32",
    "psapi",
]

MSVC_COPTS = [
    "/EHsc",
    "/bigobj",
    "/wd4996",
]

MSVC_CXXOPTS = [
    "/std:c++17",
    "/Zc:__cplusplus",
]

UNIX_COPTS = [
    "-w",
]

UNIX_CXXOPTS = [
    "-std=c++17",
]

def _flat_headers_impl(ctx):
    outputs = []
    for src in ctx.files.srcs:
        out = ctx.actions.declare_file("{}/{}".format(_INCLUDE_DIR, src.basename))
        ctx.actions.symlink(output = out, target_file = src)
        outputs.append(out)
    return [DefaultInfo(files = depset(outputs))]

_flat_headers = rule(
    implementation = _flat_headers_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
    },
)

def _globs(toolkits, patterns):
    return [
        "src/{}/{}/**/{}".format(module, toolkit, pattern)
        for module, module_toolkits in toolkits.items()
        for toolkit in module_toolkits
        for pattern in patterns
    ]

def occt_headers(name, toolkits, generated_hdrs = [], visibility = None):
    """Exposes all headers of the given toolkits through one flat include dir.

    Args:
      name: name of the resulting cc_library.
      toolkits: dict mapping an OCCT module name to its list of toolkits.
      generated_hdrs: additional (generated) headers to place in the include dir.
      visibility: visibility of the resulting cc_library.
    """
    _flat_headers(
        name = name + "_flat",
        srcs = native.glob(_globs(toolkits, _HEADER_PATTERNS), exclude = _EXCLUDES, allow_empty = True) + generated_hdrs,
    )
    cc_library(
        name = name,
        textual_hdrs = [":" + name + "_flat"],
        includes = [_INCLUDE_DIR],
        visibility = visibility,
    )

def occt_library(name, toolkits, deps = [], visibility = None):
    """Compiles all sources of the given toolkits into one cc_library.

    Args:
      name: name of the resulting cc_library.
      toolkits: dict mapping an OCCT module name to its list of toolkits.
      deps: libraries this module depends on (lower OCCT modules).
      visibility: visibility of the resulting cc_library.
    """
    cc_library(
        name = name,
        srcs = native.glob(
            _globs(toolkits, _SOURCE_PATTERNS),
            exclude = _EXCLUDES,
            allow_empty = True,
        ),
        # Some sources include neighbouring headers by relative path, so the
        # headers have to be declared here as well and not only through the
        # flat include directory.
        textual_hdrs = native.glob(
            _globs(toolkits, _HEADER_PATTERNS),
            exclude = _EXCLUDES,
            allow_empty = True,
        ),
        copts = selects.with_or({
            _MSVC_STYLE_COMPILERS: MSVC_COPTS,
            "//conditions:default": UNIX_COPTS,
        }),
        cxxopts = selects.with_or({
            _MSVC_STYLE_COMPILERS: MSVC_CXXOPTS,
            "//conditions:default": UNIX_CXXOPTS,
        }),
        defines = ["_USE_MATH_DEFINES"],
        linkopts = selects.with_or({
            _MSVC_STYLE_COMPILERS: [lib + ".lib" for lib in _WINDOWS_SYSTEM_LIBS],
            "@rules_cc//cc/compiler:mingw-gcc": ["-l" + lib for lib in _WINDOWS_SYSTEM_LIBS],
            "//conditions:default": [
                "-lpthread",
                "-ldl",
            ],
        }),
        deps = deps,
        visibility = visibility,
    )
