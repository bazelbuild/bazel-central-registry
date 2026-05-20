"""Autoconf checks used to generate Crispy Doom's config.h."""

load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")

CRISPY_CONFIG_CHECKS = [
    checks.AC_DEFINE("PACKAGE_NAME", '"Crispy Doom"'),
    checks.AC_DEFINE("PACKAGE_TARNAME", '"crispy-doom"'),
    checks.AC_DEFINE("PACKAGE_VERSION", '"7.1.0"'),
    checks.AC_DEFINE("PACKAGE_STRING", '"Crispy Doom 7.1.0"'),
    checks.AC_DEFINE("PROGRAM_PREFIX", '"crispy-"'),
    checks.AC_CHECK_HEADER("dirent.h", define = "HAVE_DIRENT_H"),
    checks.AC_CHECK_HEADER("linux/kd.h", define = "HAVE_LINUX_KD_H"),
    checks.AC_CHECK_HEADER("dev/isa/spkrio.h", define = "HAVE_DEV_ISA_SPKRIO_H"),
    checks.AC_CHECK_HEADER("dev/speaker/speaker.h", define = "HAVE_DEV_SPEAKER_SPEAKER_H"),
    checks.AC_CHECK_FUNC("qsort", define = "HAVE_QSORT"),
    checks.AC_CHECK_FUNC("mmap", define = "HAVE_MMAP"),
    checks.AC_CHECK_DECL(
        "strcasecmp",
        name = "ac_cv_have_decl_strcasecmp",
        includes = ["#include <string.h>"],
    ),
    checks.AC_DEFINE(
        "HAVE_DECL_STRCASECMP",
        condition = "ac_cv_have_decl_strcasecmp",
        if_false = 0,
        if_true = 1,
    ),
    checks.AC_CHECK_DECL(
        "strncasecmp",
        name = "ac_cv_have_decl_strncasecmp",
        includes = ["#include <string.h>"],
    ),
    checks.AC_DEFINE(
        "HAVE_DECL_STRNCASECMP",
        condition = "ac_cv_have_decl_strncasecmp",
        if_false = 0,
        if_true = 1,
    ),
    checks.AC_DEFINE("HAVE_LIBZ", "1"),
    checks.AC_DEFINE("DISABLE_SDL2NET", "1"),
]
