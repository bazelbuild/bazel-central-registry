"""Substitutions for gnulib_math.h.in.

Mirrors glib/gnulib/meson.build.  The three lists are transcribed from it
verbatim; the probe results in BUILD.bazel were measured against MSVC
14.44 / UCRT rather than guessed, since Windows is the only arm of this
port that builds gnulib -- POSIX keeps the system printf, as upstream
does there too.
"""

# meson: foreach f : unneeded_funcs -> GNULIB_<f> = 0, and HAVE_<f> and
# REPLACE_<f> set to a placeholder string.  Those two are guarded by the
# GNULIB_<f> zero and never evaluated; meson's config processor just
# cannot prove that, so it substitutes something harmless.
UNNEEDED_FUNCS = [
    "ACOSF",
    "ACOSL",
    "ASINF",
    "ASINL",
    "ATAN2F",
    "ATANF",
    "ATANL",
    "CBRT",
    "CBRTF",
    "CBRTL",
    "CEIL",
    "CEILF",
    "CEILL",
    "COPYSIGN",
    "COPYSIGNF",
    "COPYSIGNL",
    "COSF",
    "COSHF",
    "COSL",
    "EXP2",
    "EXP2F",
    "EXP2L",
    "EXPF",
    "EXPL",
    "EXPM1",
    "EXPM1F",
    "EXPM1L",
    "FABSF",
    "FABSL",
    "FLOOR",
    "FLOORF",
    "FLOORL",
    "FMA",
    "FMAF",
    "FMAL",
    "FMOD",
    "FMODF",
    "FMODL",
    "FREXPF",
    "HYPOT",
    "HYPOTF",
    "HYPOTL",
    "ILOGB",
    "ILOGBF",
    "ILOGBL",
    "LDEXPF",
    "LOG",
    "LOG10",
    "LOG10F",
    "LOG10L",
    "LOG1P",
    "LOG1PF",
    "LOG1PL",
    "LOG2",
    "LOG2F",
    "LOG2L",
    "LOGB",
    "LOGBF",
    "LOGBL",
    "LOGF",
    "LOGL",
    "MODF",
    "MODFF",
    "MODFL",
    "POWF",
    "REMAINDER",
    "REMAINDERF",
    "REMAINDERL",
    "RINT",
    "RINTF",
    "RINTL",
    "ROUND",
    "ROUNDF",
    "ROUNDL",
    "SINF",
    "SINHF",
    "SINL",
    "SQRTF",
    "SQRTL",
    "TANF",
    "TANHF",
    "TANL",
    "TRUNC",
    "TRUNCF",
    "TRUNCL",
]

# meson: foreach f : needed_funcs -> GNULIB_<f> = 1
NEEDED_FUNCS = [
    "FREXP",
    "FREXPL",
    "ISFINITE",
    "ISINF",
    "ISNAN",
    "ISNAND",
    "ISNANF",
    "ISNANL",
    "LDEXPL",
    "SIGNBIT",
]

# meson: foreach f : decls_for_unused_funcs -> HAVE_DECL_<f> = 0
DECLS_FOR_UNUSED_FUNCS = [
    "ACOSL",
    "ASINL",
    "ATANL",
    "CBRTF",
    "CBRTL",
    "CEILF",
    "CEILL",
    "COPYSIGNF",
    "COSL",
    "EXP2",
    "EXP2F",
    "EXP2L",
    "EXPL",
    "EXPM1L",
    "FLOORF",
    "FLOORL",
    "LOG10L",
    "LOG2",
    "LOG2F",
    "LOG2L",
    "LOGB",
    "LOGL",
    "REMAINDER",
    "REMAINDERL",
    "RINTF",
    "ROUND",
    "ROUNDF",
    "ROUNDL",
    "SINL",
    "SQRTL",
    "TANL",
    "TRUNC",
    "TRUNCF",
    "TRUNCL",
]

# Everything below is what meson.build's probes resolve to for MSVC/UCRT.
# Each was measured by compiling and running the probe program out of the
# matching gnulib/gl_cv_*/meson.build, which is what meson itself does for
# a native build.  Where upstream also carries a hardcoded Windows answer
# for the cross-compiling case the two agree, except that UCRT turns out
# to handle frexpl() and the '0' flag correctly where upstream's mingw
# guess says otherwise.
_PROBED = {
    # isnand/isnanf/isnanl, isfinite, isinf and signbit all link, so
    # nothing needs replacing and no extra math sources are compiled.
    "HAVE_ISNAN": "1",
    "HAVE_ISNAND": "1",
    "HAVE_ISNANF": "1",
    "HAVE_ISNANL": "1",
    "REPLACE_ISNAN": "0",
    "HAVE_ISFINITE": "1",
    "HAVE_ISFINITE_IN_LIBC": "1",
    "REPLACE_ISFINITE": "0",
    "HAVE_ISINF": "1",
    "HAVE_ISINF_IN_LIBC": "1",
    "REPLACE_ISINF": "0",
    "HAVE_SIGNBIT": "1",
    "HAVE_SIGNBIT_IN_LIBC": "1",
    "REPLACE_SIGNBIT": "0",
    "HAVE_LDEXP": "1",
    "HAVE_LDEXP_IN_LIBC": "1",
    "HAVE_LDEXPL": "1",
    "HAVE_LDEXPL_IN_LIBC": "1",
    "HAVE_FREXP": "1",
    "HAVE_FREXP_IN_LIBC": "1",
    "HAVE_FREXPL": "1",
    "HAVE_FREXPL_IN_LIBC": "1",
    # NAN is present and correct.
    "REPLACE_NAN": "0",
    # gl_cv_func_frexp_works, gl_cv_func_frexpl_works and
    # gl_cv_func_ldexpl_works all pass.
    "REPLACE_FREXP": "0",
    "REPLACE_FREXPL": "0",
    "REPLACE_LDEXPL": "0",
    # meson sets these from "<name>l prototype can be re-listed", inverted:
    # gl_cv_func_frexpl_decl ? 0 : 1.  Both re-list cleanly under MSVC.
    "HAVE_DECL_FREXPL": "0",
    "HAVE_DECL_LDEXPL": "0",
    # Unconditional in meson.build.
    "REPLACE_ITOLD": "0",
    "REPLACE_HUGE_VAL": "0",
    "REPLACE_SIGNBIT_USING_GCC": "0",
}

# gnulib_math.h is not named math.h -- glib renamed it so both it and the
# system header can be included -- so it needs no #include_next, and none
# of these carry a toolchain-specific path.
_CONSTANTS = {
    "GUARD_PREFIX": "GL",
    "INCLUDE_NEXT_AS_FIRST_DIRECTIVE": "include",
    "NEXT_AS_FIRST_DIRECTIVE_MATH_H": "<math.h>",
    "PRAGMA_COLUMNS": "",
    "PRAGMA_SYSTEM_HEADER": "",
}

def math_substitutions():
    """Returns the @VAR@ -> value map for gnulib_math.h.in."""
    subs = {}
    for f in UNNEEDED_FUNCS:
        subs["@GNULIB_" + f + "@"] = "0"
        subs["@HAVE_" + f + "@"] = "variable not used"
        subs["@REPLACE_" + f + "@"] = "variable not used"
    for f in NEEDED_FUNCS:
        subs["@GNULIB_" + f + "@"] = "1"
    for f in DECLS_FOR_UNUSED_FUNCS:
        subs["@HAVE_DECL_" + f + "@"] = "0"
    for k, v in _PROBED.items():
        subs["@" + k + "@"] = v
    for k, v in _CONSTANTS.items():
        subs["@" + k + "@"] = v
    return subs
