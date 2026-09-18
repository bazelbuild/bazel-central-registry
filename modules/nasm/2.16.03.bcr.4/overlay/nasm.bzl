"""Autoconf checks translated from nasm's `configure.ac`.

Everything here mirrors a macro invocation in the upstream `configure.ac` (and
the `PA_*` helpers under `autoconf/m4/`) so the generated `config/config.h`
matches what `./configure` would have produced. Each block is annotated with
the macro it came from.

Checks that only ever fed the generated `Makefile` -- `AC_PROG_*`,
`AC_CHECK_TOOL`, `AC_CHECK_PROGS`, `PA_LIBEXT`, `PA_ADD_CFLAGS`,
`PA_OPTION_{DEBUG,PROFILING,GC,LTO,SANITIZER}` -- have no analogue in a Bazel
build (Bazel's cc toolchain and `--compilation_mode` own those decisions) and
are deliberately omitted. The `CFLAGS_*` / `LDFLAGS_*` templates they would
have filled in are left commented out in the generated header, which is
exactly what `./configure` does when a flag is unsupported.
"""

load("@rules_cc_autoconf//autoconf:checks.bzl", "checks", "macros", "utils")

_CSYM_OK = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"

def _csym(name):
    """Convert a string to a CPP symbol the way `PA_CSYM` does.

    Args:
        name: The string to convert.

    Returns:
        `name` upper-cased with every non-identifier character replaced by an
        underscore, except `+` which becomes `X` (so `C++` -> `CXX`).
    """
    out = ""
    for char in name.upper().elems():
        if char in _CSYM_OK:
            out += char
        elif char == "+":
            out += "X"
        else:
            out += "_"
    return out

def _have(header):
    return "HAVE_" + _csym(header)

def _cache(prefix, name):
    return prefix + _csym(name).lower()

# `ac_includes_default`, plus the headers `PA_ADD_HEADERS` appends to it.
# `string.h` and `inttypes.h` are already part of the autoconf default.
_INCLUDES_DEFAULT = utils.AC_INCLUDES_DEFAULT + "#include <stdarg.h>\n"

# The contents of `autoconf/attribute.h`, which `PA_ATTRIBUTE_SYNTAX` splices
# into every attribute probe. It has to be inlined because `autoconf` checks
# compile a standalone snippet and cannot `#include` from the source tree.
_ATTRIBUTE_SYNTAX = """\
#ifndef ATTRIBUTE
# define MODERN_ATTRIBUTE(x) [[x]]
# ifndef __GNUC__
#  ifdef __cplusplus
#   ifdef __has_cpp_attribute
#    define ATTRIBUTE(x) MODERN_ATTRIBUTE(x)
#   endif
#  endif
#  ifndef ATTRIBUTE
#   ifdef __has_c_attribute
#    define ATTRIBUTE(x) MODERN_ATTRIBUTE(x)
#   endif
#  endif
#  ifndef ATTRIBUTE
#   ifdef __has_attribute
#    define ATTRIBUTE(x) MODERN_ATTRIBUTE(x)
#   endif
#  endif
# endif
# ifndef ATTRIBUTE
#  define ATTRIBUTE(x) __attribute__((x))
# endif
#endif
"""

def pa_have_func(function, args = "(0)", headers = [], define = None):
    """Translate a `PA_HAVE_FUNC` invocation.

    `PA_HAVE_FUNC` link-tests a call to `function` so that macros, builtins and
    intrinsics are detected as well as real symbols. The optional headers are
    included only when a previous `AC_CHECK_HEADERS` found them, matching the
    `#ifdef HAVE_<HEADER>` guards the macro emits.

    The guards are spelled `#if` rather than `#ifdef` because `compile_defines`
    forwards a failed header check as `#define HAVE_<HEADER> 0` instead of
    leaving it undefined, which `#ifdef` would read as a hit.

    Args:
        function: Name of the function, builtin or intrinsic to probe.
        args: Parenthesised argument list to call `function` with.
        headers: Headers to include when the matching `HAVE_*` define is set.
            Each must be checked earlier in the same `autoconf` target.
        define: Override for the generated define name.

    Returns:
        A JSON-encoded check for the `autoconf` rule.
    """
    guards = "".join([
        "#if {}\n# include <{}>\n#endif\n".format(_have(header), header)
        for header in headers
    ])
    return checks.AC_TRY_LINK(
        name = _cache("pa_cv_func_", function),
        define = define or _have(function),
        code = "{}{}\nint main(void)\n{{\n    (void){}{};\n    return 0;\n}}\n".format(
            _INCLUDES_DEFAULT,
            guards,
            function,
            args,
        ),
        compile_defines = [_have(header) for header in headers] or None,
    )

def _attribute_code(template, attribute, opts, return_type, proto_args, call_args):
    return template.format(
        includes = _INCLUDES_DEFAULT,
        syntax = _ATTRIBUTE_SYNTAX,
        attribute = attribute + ("({})".format(opts) if opts else ""),
        ret = return_type,
        proto = proto_args,
        call = call_args,
    )

_FUNC_ATTRIBUTE_TEMPLATE = """\
{includes}{syntax}
extern {ret} ATTRIBUTE({attribute}) bar({proto});
{ret} foo(void);
{ret} foo(void)
{{
	return bar({call});
}}
"""

_FUNC_PTR_ATTRIBUTE_TEMPLATE = """\
{includes}{syntax}
extern {ret} ATTRIBUTE({attribute}) (*bar1)({proto});
{ret} foo1(void);
{ret} foo1(void)
{{
	return bar1({call});
}}

typedef {ret} ATTRIBUTE({attribute}) (*bar_t)({proto});
extern bar_t bar2;
{ret} foo2(void);
{ret} foo2(void)
{{
	return bar2({call});
}}
"""

_FUNC_ATTRIBUTE_ERROR_CODE = """\
{includes}{syntax}
extern ATTRIBUTE(error("message")) void barf(void);
void foo(void);
void foo(void)
{{
	if (0)
		barf();
}}
""".format(includes = _INCLUDES_DEFAULT, syntax = _ATTRIBUTE_SYNTAX)

# The `PA_COMMON_ATTRIBUTES` list, in source order.
#
# Columns mirror `PA_FUNC_ATTRIBUTE(attribute, opts, return_type,
# prototype_args, call_args)`; empty `opts`/`return_type`/`prototype_args`/
# `call_args` fall back to the macro's defaults of `void *`, `int` and `1`.
# `suffix` is `m4_count(opts)`, which the macro splices into the define name.
_COMMON_ATTRIBUTES = [
    # (attribute, opts, suffix, return_type, prototype_args, call_args)
    ("noreturn", "", "", "void *", "int", "1"),
    ("returns_nonnull", "", "", "void *", "int", "1"),
    ("malloc", "", "", "void *", "int", "1"),
    ("alloc_size", "1", "1", "void *", "int", "80"),
    ("alloc_size", "1,2", "2", "void *", "int,int", "20,40"),
    ("sentinel", "", "", "void *", "const char *, ...", '"a","b",NULL'),
    ("format", "printf,1,2", "3", "int", "const char *, ...", '"%d",1'),
    ("const", "", "", "void *", "int", "1"),
    ("pure", "", "", "void *", "int", "1"),
    ("cold", "", "", "void *", "int", "1"),
    ("unused", "", "", "void *", "int", "1"),
]

def common_attribute_checks(copts = None):
    """Translate `PA_COMMON_ATTRIBUTES`.

    Args:
        copts: Extra flags for the probes. `PA_COMMON_ATTRIBUTES` runs
            `PA_ADD_CPPFLAGS([-Werror=attributes])` first so that compilers
            which merely warn about an unknown attribute are treated as not
            supporting it; pass that flag here for compilers that accept it.

    Returns:
        A list of JSON-encoded checks for the `autoconf` rule.
    """
    results = []
    for attribute, opts, suffix, return_type, proto_args, call_args in _COMMON_ATTRIBUTES:
        for prefix, template in (
            ("HAVE_FUNC_ATTRIBUTE", _FUNC_ATTRIBUTE_TEMPLATE),
            ("HAVE_FUNC_PTR_ATTRIBUTE", _FUNC_PTR_ATTRIBUTE_TEMPLATE),
        ):
            define = "{}{}_{}".format(
                prefix,
                suffix,
                _csym(attribute),
            )
            results.append(checks.AC_TRY_COMPILE(
                name = define.lower(),
                define = define,
                code = _attribute_code(
                    template,
                    attribute,
                    opts,
                    return_type,
                    proto_args,
                    call_args,
                ),
                copts = copts,
            ))

    # PA_FUNC_ATTRIBUTE_ERROR: checked separately because the generic probe
    # would make the compiler error out by design. No function-pointer variant
    # exists; the error attribute is never applied to one.
    results.append(checks.AC_TRY_COMPILE(
        name = "have_func_attribute_error",
        define = "HAVE_FUNC_ATTRIBUTE_ERROR",
        code = _FUNC_ATTRIBUTE_ERROR_CODE,
        copts = copts,
    ))
    return results

# Headers probed by `AC_CHECK_HEADERS` and by the `AC_CHECK_HEADERS_ONCE`
# calls hidden inside `PA_HAVE_FUNC` / `PA_ENDIAN` / `AC_FUNC_MMAP`.
# `AC_CHECK_INCLUDES_DEFAULT` already covers inttypes.h, stdint.h, stdio.h,
# stdlib.h, string.h, strings.h, sys/stat.h, sys/types.h, unistd.h and
# wchar.h, so re-checking those here would collide.
_HEADERS = [
    "endian.h",
    "fcntl.h",
    "intrin.h",
    "io.h",
    "machine/endian.h",
    "stdarg.h",
    "stdnoreturn.h",
    "sys/endian.h",
    "sys/mman.h",
    "sys/param.h",
    "sys/resource.h",
]

# `AC_CHECK_FUNCS`, in `configure.ac` order.
_FUNCS = [
    "strcasecmp",
    "stricmp",
    "strncasecmp",
    "strnicmp",
    "strsep",
    "strnlen",
    "strrchrnul",
    "iscntrl",
    "isascii",
    "mempcpy",
    "mempset",
    "getuid",
    "getgid",
    "getrlimit",
    "realpath",
    "canonicalize_file_name",
    "_fullpath",
    "pathconf",
    "_fseeki64",
    "ftruncate",
    "_chsize",
    "_chsize_s",
    "fileno",
    "_fileno",
    "getpagesize",
    "sysconf",
    "access",
    "_access",
    "faccessat",
    "strlcpy",
    "stat",
    "_stati64",
    "fstat",
    "_fstati64",
    # `S_ISREG` is a macro, so this link test never succeeds; 3.00 replaced it
    # with a `PA_HAVE_FUNC` probe. Kept as-is so the result matches
    # `./configure`.
    "S_ISREG",
]

# `AC_CHECK_DECLS`. Functions some libcs define but decline to declare when
# `__STRICT_ANSI__` is in effect.
_DECLS = [
    "strcasecmp",
    "stricmp",
    "strncasecmp",
    "strnicmp",
    "strsep",
    "strlcpy",
    "strnlen",
    "strrchrnul",
]

# `PA_ENDIAN`, which runs `PA_ADD_HEADERS(endian.h sys/endian.h
# machine/endian.h)` before its probes.
_ENDIAN_HEADERS = ["endian.h", "sys/endian.h", "machine/endian.h"]

_ENDIAN_FUNCS = [
    "cpu_to_le16",
    "cpu_to_le32",
    "cpu_to_le64",
    "__cpu_to_le16",
    "__cpu_to_le32",
    "__cpu_to_le64",
    "htole16",
    "htole32",
    "htole64",
    "__bswap_16",
    "__bswap_32",
    "__bswap_64",
    "__builtin_bswap16",
    "__builtin_bswap32",
    "__builtin_bswap64",
    "_byteswap_ushort",
    "_byteswap_ulong",
    "_byteswap_uint64",
]

# `PA_HAVE_FUNC` probes outside of `PA_ENDIAN`. `intrin.h` comes from the
# `PA_ADD_HEADERS(intrin.h)` that precedes the `ilog2()` building blocks; from
# there on it is part of `ac_includes_default`, hence its presence on the
# probes that follow.
_INTRINSICS = [
    # (function, args, headers)
    ("__builtin_expect", "(1,1)", []),
    ("__builtin_clz", "(0U)", ["intrin.h"]),
    ("__builtin_clzl", "(0UL)", ["intrin.h"]),
    ("__builtin_clzll", "(0ULL)", ["intrin.h"]),
    ("_BitScanReverse", "(0)", ["intrin.h"]),
    ("_BitScanReverse64", "(0)", ["intrin.h"]),
    ("__builtin_constant_p", "(0)", ["intrin.h"] + _ENDIAN_HEADERS),
    ("__builtin_choose_expr", "(0,1,2)", ["intrin.h"] + _ENDIAN_HEADERS),
]

def header_checks():
    """`AC_CHECK_HEADERS`, `PA_ADD_HEADERS` and `AC_HEADER_STDBOOL`.

    Returns:
        A list of JSON-encoded checks for the `autoconf` rule.
    """
    return macros.AC_CHECK_HEADERS(_HEADERS) + [
        # AC_HEADER_STDBOOL
        checks.AC_CHECK_HEADER("stdbool.h", define = "HAVE_STDBOOL_H"),
        checks.AC_CHECK_TYPE("_Bool", define = "HAVE__BOOL"),
    ]

def function_checks():
    """`AC_CHECK_FUNCS`, `AC_CHECK_DECLS`, `AC_FUNC_*` and the `PA_*` probes.

    Returns:
        A list of JSON-encoded checks for the `autoconf` rule.
    """
    return macros.AC_CHECK_FUNCS(_FUNCS) + [
        # AC_FUNC_FSEEKO
        checks.AC_CHECK_FUNC("fseeko", define = "HAVE_FSEEKO"),
        checks.AC_DEFINE("_LARGEFILE_SOURCE", 1),
        # AC_FUNC_MMAP
        checks.AC_CHECK_FUNC("mmap", define = "HAVE_MMAP"),
        # AC_CHECK_TYPES([struct stat])
        checks.AC_CHECK_TYPE(
            "struct stat",
            name = "ac_cv_type_struct_stat",
            define = "HAVE_STRUCT_STAT",
        ),
        # AC_CHECK_TYPES([struct _stati64])
        checks.AC_CHECK_TYPE(
            "struct _stati64",
            name = "ac_cv_type_struct__stati64",
            define = "HAVE_STRUCT__STATI64",
        ),
        # PA_FUNC_SNPRINTF / PA_FUNC_VSNPRINTF. Upstream falls back to the
        # `_snprintf` spelling for pre-2015 MSVC; every toolchain Bazel
        # supports has the C99 names, so only those are probed and the
        # `snprintf` / `vsnprintf` rename templates stay commented out.
        checks.AC_CHECK_FUNC("snprintf", define = "HAVE_SNPRINTF"),
        checks.AC_CHECK_FUNC("vsnprintf", define = "HAVE_VSNPRINTF"),
    ] + macros.AC_CHECK_DECLS(_DECLS) + [
        pa_have_func(function, args, headers)
        for function, args, headers in _INTRINSICS
    ] + [
        pa_have_func(function, headers = ["intrin.h"] + _ENDIAN_HEADERS)
        for function in _ENDIAN_FUNCS
    ]

# PA_VARIADIC_MACROS
_VARIADIC_MACROS_CODE = """\
{includes}
#define myprintf(f, ...) printf(f, __VA_ARGS__)
int main(void)
{{
	myprintf("%s", "Hello, World!\\n");
	return 0;
}}
""".format(includes = _INCLUDES_DEFAULT)

# PA_CHECK_BAD_STDC_INLINE
_STDC_INLINE_CODE = """\
{includes}

/* Don't mistake GNU inlines for c99 */
#if defined(__GNUC__) && !defined(__GNUC_STDC_INLINE__)
# error "Using gnu inline standard"
#endif

inline int foo(int x)
{{
	return x+1;
}}
""".format(includes = _INCLUDES_DEFAULT)

# PA_C_TYPEOF
_TYPEOF_TEMPLATE = """\
{includes}
int testme(int x);
int testme(int x)
{{
    {spelling}(x) y = x*x;
    return y;
}}
"""

def _typeof_code(spelling):
    return _TYPEOF_TEMPLATE.format(includes = _INCLUDES_DEFAULT, spelling = spelling)

def compiler_checks():
    """The remaining compiler-feature probes from `configure.ac`.

    Returns:
        A list of JSON-encoded checks for the `autoconf` rule.
    """
    return [
        # AC_C_RESTRICT
        checks.AC_C_RESTRICT(),
        # PA_VARIADIC_MACROS
        checks.AC_TRY_LINK(
            name = "pa_cv_variadic_macros",
            define = "HAVE_VARIADIC_MACROS",
            code = _VARIADIC_MACROS_CODE,
        ),
        # PA_CHECK_BAD_STDC_INLINE
        checks.AC_TRY_COMPILE(
            name = "pa_cv_stdc_inline",
            define = "HAVE_STDC_INLINE",
            code = _STDC_INLINE_CODE,
        ),
        # PA_C_TYPEOF. Upstream walks `typeof __typeof __typeof__ decltype
        # __decltype __decltype__ _Decltype` and renames `typeof` to the first
        # spelling that works. Only the first two are probed here: `typeof` is
        # C23 and a long-standing GNU extension, and `__typeof__` covers GNU
        # compilers put into a strict-ANSI mode. The rest are C++ or
        # long-dead-compiler spellings.
        checks.AC_TRY_COMPILE(
            name = "pa_cv_typeof_typeof",
            code = _typeof_code("typeof"),
        ),
        checks.AC_TRY_COMPILE(
            name = "pa_cv_typeof___typeof__",
            code = _typeof_code("__typeof__"),
            requires = ["!pa_cv_typeof_typeof"],
        ),
        checks.AC_DEFINE(
            "HAVE_TYPEOF",
            condition = "pa_cv_typeof_typeof || pa_cv_typeof___typeof__",
            if_true = 1,
            if_false = None,
        ),
        checks.AC_DEFINE(
            "typeof",
            condition = "pa_cv_typeof___typeof__",
            if_true = "__typeof__",
            if_false = None,
        ),
        # AC_TYPE_UINTPTR_T
        checks.AC_CHECK_TYPE(
            "uintptr_t",
            name = "ac_cv_type_uintptr_t",
            define = "HAVE_UINTPTR_T",
        ),
        checks.AC_DEFINE(
            "uintptr_t",
            "unsigned long int",
            requires = ["!ac_cv_type_uintptr_t"],
        ),
    ]
