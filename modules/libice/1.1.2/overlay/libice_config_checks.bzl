"""Autoconf-style checks used to generate libICE's config.h.

Mirrors the probes in upstream configure.ac (plus the XTRANS_CONNECTION_FLAGS
macro from xorg-macros), evaluated against Bazel's configured cc_toolchain.
Standard C header checks and the AC_USE_SYSTEM_EXTENSIONS feature macros come
from the macro targets listed in the autoconf_hdr deps.
"""

load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")

LIBICE_CONFIG_CHECKS = [
    # XTRANS_CONNECTION_FLAGS: transport support. TCP and Unix-domain sockets
    # are available on every platform we build for; IPv6 follows sockaddr_in6.
    checks.AC_DEFINE("TCPCONN", "1"),
    checks.AC_DEFINE("UNIXCONN", "1"),
    checks.AC_CHECK_TYPE(
        "struct sockaddr_in6",
        define = "IPv6",
        includes = [
            "#include <sys/types.h>",
            "#include <sys/socket.h>",
            "#include <netinet/in.h>",
        ],
    ),
    checks.AC_CHECK_TYPE(
        "socklen_t",
        define = "HAVE_SOCKLEN_T",
        includes = [
            "#include <sys/types.h>",
            "#include <sys/socket.h>",
        ],
    ),

    # configure.ac: Xtrans role for this library
    checks.AC_DEFINE("ICE_t", "1"),
    checks.AC_DEFINE("TRANS_CLIENT", "1"),
    checks.AC_DEFINE("TRANS_SERVER", "1"),

    # configure.ac: AC_CHECK_FUNCS([asprintf arc4random_buf getentropy])
    # Upstream prefers arc4random_buf and only falls back to getentropy;
    # the source guards (#ifdef HAVE_ARC4RANDOM_BUF / HAVE_GETENTROPY) already
    # encode that preference, so both are probed independently here.
    checks.AC_CHECK_FUNC("asprintf", define = "HAVE_ASPRINTF"),
    checks.AC_CHECK_FUNC("arc4random_buf", define = "HAVE_ARC4RANDOM_BUF"),
    checks.AC_CHECK_FUNC("getentropy", define = "HAVE_GETENTROPY"),
    checks.AC_CHECK_FUNC("strcasecmp", define = "HAVE_STRCASECMP"),
    checks.AC_CHECK_FUNC("strlcpy", define = "HAVE_STRLCPY"),

    # AC_INIT([libICE], [1.1.2], [https://gitlab.freedesktop.org/xorg/lib/libice/-/issues])
    checks.AC_DEFINE("PACKAGE_NAME", '"libICE"'),
    checks.AC_DEFINE("PACKAGE_TARNAME", '"libICE"'),
    checks.AC_DEFINE("PACKAGE_VERSION", '"1.1.2"'),
    checks.AC_DEFINE("PACKAGE_STRING", '"libICE 1.1.2"'),
    checks.AC_DEFINE("PACKAGE_BUGREPORT", '"https://gitlab.freedesktop.org/xorg/lib/libice/-/issues"'),
    checks.AC_DEFINE("PACKAGE_URL", '""'),
    # XORG_MACROS version split
    checks.AC_DEFINE("PACKAGE_VERSION_MAJOR", "1"),
    checks.AC_DEFINE("PACKAGE_VERSION_MINOR", "1"),
    checks.AC_DEFINE("PACKAGE_VERSION_PATCHLEVEL", "2"),
]
