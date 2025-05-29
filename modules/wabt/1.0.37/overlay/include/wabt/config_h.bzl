# Generates `config.h` from `config.h.in`, approximately matching the behavior
# of CMake.

_DETECT_COMPILER = """
#if defined(__clang__)
#  define COMPILER_IS_CLANG 1
#  define COMPILER_IS_GNU 0
#  define COMPILER_IS_MSVC 0
#elif defined(__GNUC__)
#  define COMPILER_IS_CLANG 0
#  define COMPILER_IS_GNU 1
#  define COMPILER_IS_MSVC 0
#elif defined(_MSC_VER)
#  define COMPILER_IS_CLANG 0
#  define COMPILER_IS_GNU 0
#  define COMPILER_IS_MSVC 1
#endif
"""

_HAVE_SNPRINTF = """
#if defined(_MSC_VER)
#  define HAVE_SNPRINTF 0
#else
#  define HAVE_SNPRINTF 1
#endif
"""

_HAVE_STRCASECMP = """
#if defined(_MSC_VER)
#  define HAVE_STRCASECMP 0
#else
#  define HAVE_STRCASECMP 1
#endif
"""

_HAVE_SSIZE_T = """
#if defined(_WIN32)
#  define HAVE_SSIZE_T 0
#else
#  define HAVE_STRCASECMP 1
#endif
"""

_SIZEOF_SIZE_T = """
#if defined(__clang__) || defined(__GNUC__)
#  define SIZEOF_SIZE_T __SIZEOF_SIZE_T__
#elif defined(_WIN64)
#  define SIZEOF_SIZE_T 8
#elif defined(_WIN32)
#  define SIZEOF_SIZE_T 4
#endif
"""

_WABT_BIG_ENDIAN = """
#if defined(_MSC_VER)
#  define WABT_BIG_ENDIAN 0
#elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#  define WABT_BIG_ENDIAN 1
#else
#  define WABT_BIG_ENDIAN 0
#endif
"""

def _config_h_impl(ctx):
    substitutions = {
        "#cmakedefine WABT_VERSION_STRING ": "#define WABT_VERSION_STRING ",
        "@WABT_VERSION_STRING@": ctx.attr.version,
        "#cmakedefine01 HAVE_OPENSSL_SHA_H": "#define HAVE_OPENSSL_SHA_H 0",
        "#cmakedefine01 WITH_EXCEPTIONS": "#define WITH_EXCEPTIONS 0",
        "#cmakedefine01 HAVE_WIN32_VT100": "#define HAVE_WIN32_VT100 0",
        "#cmakedefine01 HAVE_SNPRINTF": _HAVE_SNPRINTF,
        "#cmakedefine01 HAVE_STRCASECMP": _HAVE_STRCASECMP,
        "#cmakedefine01 HAVE_SSIZE_T": _HAVE_SSIZE_T,
        "#cmakedefine01 WABT_BIG_ENDIAN": _WABT_BIG_ENDIAN,
        "#define SIZEOF_SIZE_T @SIZEOF_SIZE_T@": _SIZEOF_SIZE_T,
        "#cmakedefine01 COMPILER_IS_CLANG": _DETECT_COMPILER,
        "#cmakedefine01 COMPILER_IS_GNU": "",
        "#cmakedefine01 COMPILER_IS_MSVC": "",
    }

    wabt_debug = ""
    if ctx.var.get("COMPILATION_MODE", "") == "dbg":
        wabt_debug += "#define WABT_DEBUG"
    substitutions["#cmakedefine WABT_DEBUG @WABT_DEBUG@"] = wabt_debug

    # Assume `alloca()` is available in `<alloca.h>` on Linux
    if ctx.attr.target_os == "linux":
        have_alloca_h = "#define HAVE_ALLOCA_H 1"
    else:
        have_alloca_h = "#define HAVE_ALLOCA_H 0"
    substitutions["#cmakedefine01 HAVE_ALLOCA_H"] = have_alloca_h

    # Assume `<unistd.h>` is available unless on Windows
    if ctx.attr.target_os == "windows":
        have_unistd_h = "#define HAVE_UNISTD_H 0"
    else:
        have_unistd_h = "#define HAVE_UNISTD_H 1"
    substitutions["#cmakedefine01 HAVE_UNISTD_H"] = have_unistd_h

    out = ctx.actions.declare_file("config.h")
    ctx.actions.expand_template(
        template = ctx.file._config_h_in,
        output = out,
        substitutions = substitutions,
    )
    return DefaultInfo(files = depset([out]))

_config_h = rule(
    implementation = _config_h_impl,
    attrs = {
        "_config_h_in": attr.label(
            allow_single_file = True,
            default = Label("//src:config_h_in"),
        ),
        "version": attr.string(),
        "target_os": attr.string(),
    },
)

def config_h(*, name):
    _config_h(
        name = name,
        version = native.module_version(),
        target_os = select({
            "@platforms//os:linux": "linux",
            "@platforms//os:windows": "windows",
            "//conditions:default": "",
        }),
    )
