"""Autoconf-style checks used to generate dbus's config.h.

Mirrors the probes in upstream cmake/CMakeLists.txt + cmake/ConfigureChecks.cmake,
evaluated against Bazel's configured cc_toolchain. Byte order comes from the
AC_C_BIGENDIAN macro target listed in the autoconf_hdr deps.
"""

load("@rules_cc_autoconf//autoconf:checks.bzl", "checks", "macros")

_SOCKET_INCLUDES = [
    "#include <sys/types.h>",
    "#include <sys/socket.h>",
]

DBUS_CONFIG_CHECKS = [
    checks.AC_DEFINE("VERSION", '"1.16.2"'),
    checks.AC_DEFINE("_GNU_SOURCE", 1),

    # --- Installation layout / defaults (CMake cache variables) -------------
    checks.AC_DEFINE("DBUS_DATADIR", '"/usr/share"'),
    checks.AC_DEFINE("DBUS_BINDIR", '"/usr/bin"'),
    checks.AC_DEFINE("DBUS_PREFIX", '"/usr"'),
    checks.AC_DEFINE("DBUS_SYSTEM_CONFIG_FILE", '"/etc/dbus-1/system.conf"'),
    checks.AC_DEFINE("DBUS_SESSION_CONFIG_FILE", '"/etc/dbus-1/session.conf"'),
    checks.AC_DEFINE("DBUS_SESSION_SOCKET_DIR", '"/tmp"'),
    checks.AC_DEFINE("DBUS_DAEMON_NAME", '"dbus-daemon"'),
    checks.AC_DEFINE("DBUS_SYSTEM_BUS_DEFAULT_ADDRESS", '"unix:path=/run/dbus/system_bus_socket"'),
    checks.AC_DEFINE("DBUS_SESSION_BUS_CONNECT_ADDRESS", '"autolaunch:"'),
    checks.AC_DEFINE("DBUS_MACHINE_UUID_FILE", '"/etc/machine-id"'),
    checks.AC_DEFINE("DBUS_DAEMONDIR", '"/usr/bin"'),
    checks.AC_DEFINE("DBUS_RUNSTATEDIR", '"/run"'),
    checks.AC_DEFINE("DBUS_USER", '"messagebus"'),
    checks.AC_DEFINE("DBUS_TEST_USER", '"nobody"'),
    checks.AC_DEFINE("DBUS_EXEEXT", '""'),
    checks.AC_DEFINE("DBUS_CONSOLE_OWNER_FILE", '""'),

    # --- Build options (release configuration) ------------------------------
    checks.AC_DEFINE("DBUS_DISABLE_ASSERT", 1),
    # DBUS_DISABLE_CHECKS intentionally left undefined -> DBUS_ENABLE_CHECKS.

    # --- Headers (check_include_file) ---------------------------------------
] + macros.AC_CHECK_HEADERS([
    "afunix.h",
    "alloca.h",
    "byteswap.h",
    "crt_externs.h",
    "dirent.h",
    "errno.h",
    "inttypes.h",
    "io.h",
    "locale.h",
    "signal.h",
    "stdio.h",
    "stdatomic.h",
    "syslog.h",
    "sys/events.h",
    "sys/inotify.h",
    "linux/magic.h",
    "sys/prctl.h",
    "sys/random.h",
    "sys/resource.h",
    "sys/syscall.h",
    "sys/vfs.h",
    "sys/time.h",
    "unistd.h",
    "ws2tcpip.h",
]) + [

    # --- Functions (check_symbol_exists / check_function_exists) ------------
] + macros.AC_CHECK_FUNCS([
    "accept4",
    "backtrace",
    "clearenv",
    "closefrom",
    "close_range",
    "fstatfs",
    "getgrouplist",
    "getpeerucred",
    "getpwnam_r",
    "getrandom",
    "getresuid",
    "getrlimit",
    "inotify_init1",
    "localeconv",
    "nanosleep",
    "pipe2",
    "poll",
    "prctl",
    "prlimit",
    "raise",
    "setenv",
    "setlocale",
    "setresuid",
    "setrlimit",
    "socketpair",
    "unsetenv",
    "writev",
]) + [

    # --- Types / members ----------------------------------------------------
    checks.AC_CHECK_TYPE("socklen_t", define = "HAVE_SOCKLEN_T", includes = _SOCKET_INCLUDES),
    # BSD credential passing (struct cmsgcred); Linux uses SO_PEERCRED instead.
    checks.AC_CHECK_MEMBER(
        "struct cmsgcred.cmcred_pid",
        define = "HAVE_CMSGCRED",
        includes = _SOCKET_INCLUDES,
    ),

    # --- Platform features --------------------------------------------------
    # CMake: check_c_source_compiles for SCM_RIGHTS fd passing via msghdr.
    checks.AC_TRY_COMPILE(
        name = "dbus_cv_unix_fd_passing",
        define = "HAVE_UNIX_FD_PASSING",
        includes = _SOCKET_INCLUDES,
        # With `includes`, `code` is the body of main().
        code = """
struct msghdr msg;
struct cmsghdr *cmsg;
union { struct cmsghdr hdr; char buf[CMSG_SPACE(sizeof(int))]; } u;
msg.msg_control = u.buf;
msg.msg_controllen = sizeof(u.buf);
cmsg = CMSG_FIRSTHDR(&msg);
cmsg->cmsg_level = SOL_SOCKET;
cmsg->cmsg_type = SCM_RIGHTS;
return 0;
""",
    ),
    # CMake: check_symbol_exists(epoll_create1 sys/epoll.h)
    checks.AC_TRY_COMPILE(
        name = "dbus_cv_linux_epoll",
        define = "DBUS_HAVE_LINUX_EPOLL",
        includes = ["#include <sys/epoll.h>"],
        code = "return epoll_create1(0) < 0;",
    ),
    # CMake: check_c_source_compiles for GCC __sync builtins (-> #cmakedefine01)
    checks.AC_TRY_COMPILE(
        name = "dbus_cv_use_sync",
        define = "DBUS_USE_SYNC",
        code = "int main(void) { int a = 4; __sync_sub_and_fetch(&a, 4); return 0; }",
    ),

    # --- Declarations (#cmakedefine01, always rendered as 0/1) --------------
    checks.AC_CHECK_DECL(
        "environ",
        define = "HAVE_DECL_ENVIRON",
        includes = ["#include <unistd.h>"],
        compile_defines = ["_GNU_SOURCE"],
    ),
    checks.AC_CHECK_DECL(
        "LOG_PERROR",
        define = "HAVE_DECL_LOG_PERROR",
        includes = ["#include <syslog.h>"],
    ),
    checks.AC_CHECK_DECL(
        "MSG_NOSIGNAL",
        define = "HAVE_DECL_MSG_NOSIGNAL",
        includes = _SOCKET_INCLUDES,
    ),
    checks.AC_CHECK_DECL(
        "SYS_pidfd_open",
        define = "HAVE_DECL_SYS_PIDFD_OPEN",
        includes = ["#include <sys/syscall.h>"],
    ),
]
