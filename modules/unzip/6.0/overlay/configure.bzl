"""The probes of unix/configure, as rules_cc_autoconf checks.

unix/configure is a hand-written shell script, not an autoconf one: it
compiles a small program per question and appends `-D` flags to the `flags`
file the Makefile's `generic` target then compiles with.  Every probe is here
in the script's order, under the line of unix/configure that adds the flag.
What it leaves out is what Bazel owns: the compiler's optimization and ANSI
options, the choice of preprocessor, and the i386 assembler CRC (never built
here, as on every 64-bit host).  The two probes configure *runs* (large files,
wide characters) are answered at compile time instead so they hold when the
build is for another platform.
"""

load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")

visibility("private")

# Line 292.  configure's program runs and checks sizeof(off_t) and
# sizeof(struct stat.st_size) under the LFS feature macros; the arrays
# fail to compile when either is under 8 bytes.
_LARGE_FILE_PROGRAM = """\
#define _LARGEFILE_SOURCE
#define _LARGEFILE64_SOURCE
#define _FILE_OFFSET_BITS 64
#define _LARGE_FILES
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
int off_t_is_64_bit[sizeof(off_t) >= 8 ? 1 : -1];
int st_size_is_64_bit[sizeof(((struct stat *)0)->st_size) >= 8 ? 1 : -1];
int main(void) { return 0; }
"""

# Line 339.  configure's program returns 2 (Unicode) only when the compiler
# defines __STDC_ISO_10646__, so that is the whole question.
_WIDE_CHAR_PROGRAM = """\
#include <stdlib.h>
#include <stdio.h>
#include <wchar.h>
#ifndef __STDC_ISO_10646__
#error wchar_t encoding unspecified
#endif
int main(void) {
  wchar_t *wide_string = (wchar_t *)malloc(4 * sizeof(wchar_t));
  size_t wsize = mbstowcs(wide_string, "foo", 3);
  wide_string[wsize] = 0;
  return 0;
}
"""

# Lines 507 and 511.  configure compiles this with the flags so far, so
# HAVE_MBSTRING_H is a replayed result here; a header that was not found
# replays as 0, hence `#if` where the script has `#ifdef`.
_MBCS_PROGRAM = """\
#include <stdlib.h>
#include <stdio.h>
#include <wchar.h>
#if HAVE_MBSTRING_H
#  include <mbstring.h>
#endif
int main(void) {
  char *tst = "Hallo";
  return mblen(tst, MB_CUR_MAX);
}
"""

# Line 387: the functions whose absence is a NO_<FUNCTION> flag.
_FUNCTIONS = [
    "fchmod",
    "fchown",
    "lchown",
    "nl_langinfo",
]

# Line 464: the headers whose absence is a NO_<HEADER>_H flag.
_HEADERS = [
    "stdlib.h",
    "stddef.h",
    "unistd.h",
    "fcntl.h",
    "string.h",
    "langinfo.h",
]

def _macro(header):
    """The HAVE_/NO_ suffix configure makes from a header name: `sys/dir.h` -> `SYS_DIR_H`."""
    return header.replace("/", "_").replace(".", "_").upper()

def _first_of(headers):
    """configure's `for inc in ...; break` loops: HAVE_<HEADER> for the first header found only."""
    found = []
    result = []
    for header in headers:
        define = "HAVE_" + _macro(header)
        result.append(checks.AC_CHECK_HEADER(header, define = define, requires = ["!" + f for f in found]))
        found.append(define)
    return result

CONFIGURE_CHECKS = [
    # Line 195.
    checks.AC_TRY_COMPILE(name = "ac_cv_prototypes", code = "int main(int argc, char *argv[]) { return 0; }"),
    checks.AC_DEFINE("NO_PROTO", requires = ["!ac_cv_prototypes"]),
    # Line 210.
    checks.AC_TRY_COMPILE(
        name = "ac_cv_const",
        code = "typedef int charset[2];\nint main(void) { const charset x; const char *foo; return 0; }",
    ),
    checks.AC_DEFINE("NO_CONST", requires = ["!ac_cv_const"]),
    # Lines 223, 235 and 247.
    checks.AC_CHECK_TYPE("time_t", name = "ac_cv_type_time_t", includes = ["#include <sys/types.h>", "#include <time.h>"]),
    checks.AC_DEFINE("NO_TIME_T", requires = ["!ac_cv_type_time_t"]),
    checks.AC_CHECK_TYPE("size_t", name = "ac_cv_type_size_t", includes = ["#include <sys/types.h>"]),
    checks.AC_DEFINE("NO_SIZE_T", requires = ["!ac_cv_type_size_t"]),
    checks.AC_CHECK_TYPE("off_t", name = "ac_cv_type_off_t", includes = ["#include <sys/types.h>"]),
    checks.AC_DEFINE("NO_OFF_T", requires = ["!ac_cv_type_off_t"]),
    # Line 292.
    checks.AC_TRY_COMPILE(define = "LARGE_FILE_SUPPORT", code = _LARGE_FILE_PROGRAM),
    # Line 339.
    checks.AC_TRY_COMPILE(name = "ac_cv_unicode_wchar", code = _WIDE_CHAR_PROGRAM),
    checks.AC_DEFINE("UNICODE_WCHAR", requires = ["ac_cv_unicode_wchar"]),
    # Lines 358 and 361.  Both the wide character and the setlocale probe add
    # UNICODE_SUPPORT, so it is one define with either as its condition.
    checks.AC_TRY_COMPILE(
        name = "ac_cv_setlocale",
        code = 'char *loc = setlocale(LC_CTYPE, ""); (void)loc;',
        includes = ["#include <locale.h>"],
    ),
    checks.AC_DEFINE("UTF8_MAYBE_NATIVE", requires = ["ac_cv_setlocale"]),
    checks.AC_DEFINE("NO_SETLOCALE", requires = ["!ac_cv_setlocale"]),
    checks.AC_DEFINE(
        "UNICODE_SUPPORT",
        condition = "ac_cv_unicode_wchar || ac_cv_setlocale",
        if_false = None,
        if_true = 1,
    ),
] + [
    # Line 387.
    checks.AC_CHECK_FUNC(function, name = "ac_cv_func_" + function)
    for function in _FUNCTIONS
] + [
    checks.AC_DEFINE("NO_" + function.upper(), requires = ["!ac_cv_func_" + function])
    for function in _FUNCTIONS
] + [
    # Line 406.
    checks.AC_CHECK_FUNC("memset", name = "ac_cv_func_memset"),
    checks.AC_DEFINE("ZMEM", requires = ["!ac_cv_func_memset"]),
    # Line 418.
    checks.AC_TRY_COMPILE(name = "ac_cv_errno_decl", code = "errno = 0;", includes = ["#include <errno.h>"]),
    checks.AC_DEFINE("NO_ERRNO", requires = ["!ac_cv_errno_decl"]),
    # Line 436: the directory functions, in libc or one of the old libraries,
    # which goes on the link line (LFLAGS2) through :configure_linkopts.
    checks.AC_SEARCH_LIBS(
        "opendir",
        ["ndir", "dir", "ucb", "bsd", "BSD", "PW", "x", "dirent"],
        name = "ac_cv_search_opendir",
        subst = "DIR_LIB",
    ),
    checks.AC_DEFINE("NO_DIR", requires = ["!ac_cv_search_opendir"]),
    # Line 444: Dynix/ptx kept readlink in -lseq.
    checks.AC_SEARCH_LIBS("readlink", ["seq"], subst = "READLINK_LIB"),
] + _first_of([
    # Line 457.
    "dirent.h",
    "sys/ndir.h",
    "ndir.h",
    "sys/dir.h",
]) + [
    # Line 464.
    checks.AC_CHECK_HEADER(header, name = "ac_cv_header_" + _macro(header).lower())
    for header in _HEADERS
] + [
    checks.AC_DEFINE("NO_" + _macro(header), requires = ["!ac_cv_header_" + _macro(header).lower()])
    for header in _HEADERS
] + _first_of([
    # Line 475.
    "termios.h",
    "termio.h",
    "sgtty.h",
]) + _first_of([
    # Line 485.
    "mbstring.h",
    "mbctype.h",
]) + [
    # Lines 507 and 511.
    checks.AC_TRY_LINK(name = "ac_cv_mbcs", code = _MBCS_PROGRAM, compile_defines = ["HAVE_MBSTRING_H"]),
    checks.AC_DEFINE("_MBCS", requires = ["ac_cv_mbcs"]),
    checks.AC_DEFINE("NO_MBCS", requires = ["!ac_cv_mbcs"]),
    # Line 519: MBSCHR=mbschr when the C library has it, likewise MBSRCHR.
    checks.AC_CHECK_FUNC("mbschr", name = "ac_cv_func_mbschr", requires = ["ac_cv_mbcs"]),
    checks.AC_DEFINE_UNQUOTED("MBSCHR", "mbschr", requires = ["ac_cv_func_mbschr"]),
    checks.AC_CHECK_FUNC("mbsrchr", name = "ac_cv_func_mbsrchr", requires = ["ac_cv_mbcs"]),
    checks.AC_DEFINE_UNQUOTED("MBSRCHR", "mbsrchr", requires = ["ac_cv_func_mbsrchr"]),
    # Line 534.  MMAP is never defined in this build, so this fails only
    # with a compiler that cannot build an empty function.
    checks.AC_TRY_COMPILE(name = "ac_cv_valloc", code = "int main(void) {\n#ifdef MMAP\n  valloc();\n#endif\n  return 0;\n}"),
    checks.AC_DEFINE("NO_VALLOC", requires = ["!ac_cv_valloc"]),
]

# Line 400.  configure links a program that calls lchmod() on a symlink and
# runs it.  Linux C libraries have the function but no way to implement it
# (glibc and musl return EOPNOTSUPP for a symlink), so the run fails there
# and NO_LCHMOD is the answer; everywhere else having the function is enough.
LCHMOD_CHECKS_LINUX = [
    checks.AC_DEFINE("NO_LCHMOD"),
]

LCHMOD_CHECKS = [
    checks.AC_CHECK_FUNC("lchmod", name = "ac_cv_func_lchmod"),
    checks.AC_DEFINE("NO_LCHMOD", requires = ["!ac_cv_func_lchmod"]),
]
