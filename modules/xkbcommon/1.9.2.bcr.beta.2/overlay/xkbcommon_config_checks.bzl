"""Autoconf-style checks used to generate libxkbcommon's config.h."""

load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")

XKBCOMMON_CONFIG_CHECKS = [
    checks.AC_DEFINE("_GNU_SOURCE", "1"),
    checks.AC_DEFINE("EXIT_INVALID_USAGE", "2"),
    checks.AC_DEFINE("DFLT_XKB_CONFIG_ROOT", '"/usr/share/X11/xkb"'),
    checks.AC_DEFINE("DFLT_XKB_CONFIG_EXTRA_PATH", '"/etc/xkb"'),
    checks.AC_DEFINE("XLOCALEDIR", '"/usr/share/X11/locale"'),
    checks.AC_DEFINE("DEFAULT_XKB_RULES", '"evdev"'),
    checks.AC_DEFINE("DEFAULT_XKB_MODEL", '"pc105"'),
    checks.AC_DEFINE("DEFAULT_XKB_LAYOUT", '"us"'),
    checks.AC_DEFINE("DEFAULT_XKB_VARIANT", "NULL"),
    checks.AC_DEFINE("DEFAULT_XKB_OPTIONS", "NULL"),
    checks.AC_CHECK_HEADER("unistd.h", define = "HAVE_UNISTD_H"),
    checks.AC_CHECK_FUNC("asprintf", define = "HAVE_ASPRINTF"),
    checks.AC_CHECK_FUNC("eaccess", define = "HAVE_EACCESS"),
    checks.AC_CHECK_FUNC("euidaccess", define = "HAVE_EUIDACCESS"),
    checks.AC_CHECK_FUNC("mmap", define = "HAVE_MMAP"),
    checks.AC_CHECK_FUNC("secure_getenv", define = "HAVE_SECURE_GETENV"),
    checks.AC_CHECK_FUNC("strndup", define = "HAVE_STRNDUP"),
    checks.AC_CHECK_FUNC("vasprintf", define = "HAVE_VASPRINTF"),
    checks.AC_CHECK_FUNC("__secure_getenv", define = "HAVE___SECURE_GETENV"),
]
