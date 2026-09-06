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
    checks.AC_CHECK_FUNC("ioperm", define = "HAVE_IOPERM"),
    checks.AC_DEFINE("HAVE_DECL_STRCASECMP", "1"),
    checks.AC_DEFINE("HAVE_DECL_STRNCASECMP", "1"),
    checks.AC_DEFINE("HAVE_LIBZ", "1"),
    checks.AC_DEFINE("CRISPY_TRUECOLOR", "1"),
    checks.AC_DEFINE("DISABLE_SDL2NET", "1"),
]
