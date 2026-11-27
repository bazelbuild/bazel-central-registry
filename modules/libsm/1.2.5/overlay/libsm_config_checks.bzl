"""Autoconf-style checks used to generate libSM's config.h.

Mirrors the probes in upstream configure.ac (plus the XTRANS_CONNECTION_FLAGS
macro from xorg-macros), evaluated against Bazel's configured cc_toolchain.
Standard C header checks (HAVE_STDINT_H, ...) come from the
AC_CHECK_INCLUDES_DEFAULT macro target listed in the autoconf_hdr deps.
"""

load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")

LIBSM_CONFIG_CHECKS = [
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

    # configure.ac
    checks.AC_CHECK_FUNC("strcasecmp", define = "HAVE_STRCASECMP"),
    checks.AC_CHECK_FUNC("strlcpy", define = "HAVE_STRLCPY"),
    # BSD/macOS provide uuid_create(3); elsewhere upstream falls back to
    # libuuid (HAVE_LIBUUID), which we do not link, so SmsGenerateClientID
    # returns NULL on those platforms exactly as with --without-libuuid.
    checks.AC_CHECK_FUNC("uuid_create", define = "HAVE_UUID_CREATE"),

    # AC_INIT([libSM], [1.2.5], [https://gitlab.freedesktop.org/xorg/lib/libsm/-/issues])
    checks.AC_DEFINE("PACKAGE_NAME", '"libSM"'),
    checks.AC_DEFINE("PACKAGE_TARNAME", '"libSM"'),
    checks.AC_DEFINE("PACKAGE_VERSION", '"1.2.5"'),
    checks.AC_DEFINE("PACKAGE_STRING", '"libSM 1.2.5"'),
    checks.AC_DEFINE("PACKAGE_BUGREPORT", '"https://gitlab.freedesktop.org/xorg/lib/libsm/-/issues"'),
    checks.AC_DEFINE("PACKAGE_URL", '""'),
    # XORG_MACROS version split
    checks.AC_DEFINE("PACKAGE_VERSION_MAJOR", "1"),
    checks.AC_DEFINE("PACKAGE_VERSION_MINOR", "2"),
    checks.AC_DEFINE("PACKAGE_VERSION_PATCHLEVEL", "5"),
]
