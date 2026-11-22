"""Feature checks for SDL's Linux build configuration header.

SDL supplies hand-written headers for Windows and Apple platforms, and
generates the Linux header with CMake. These checks do the same work with
rules_cc_autoconf, against the toolchain and the sysroot that Bazel uses.
Each group links to the CMake lines that it copies.

The file has two kinds of entry:

  * checks, wherever CMake examines the system. CMake's check_symbol_exists
    and check_c_source_compiles build and link an executable, and these
    checks do the same;
  * fixed AC_DEFINEs, where CMake's answer follows from a build option or
    from a dependency in MODULE.bazel. The checks cannot see the X11,
    Wayland, xkbcommon and ALSA modules, so this file sets those values.
    Where a macro decides which symbols SDL demands at runtime, use the
    oldest library version that SDL supports, not the minimum version in
    MODULE.bazel.

A template entry with no check becomes `/* #undef NAME */`, and autoconf_hdr
drops a check that has no template entry. Neither case gives a warning.

To compare the generated header with SDL's own configure step, use a Linux
machine that has the X11, Wayland, xkbcommon, ALSA, GL and EGL development
packages:

    cmake -S SDL3-<version> -B build -DCMAKE_BUILD_TYPE=Release \
      -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF \
      -DSDL_TEST_LIBRARY=OFF -DSDL_INSTALL=OFF \
      -DSDL_ALSA=ON -DSDL_PULSEAUDIO=OFF -DSDL_PIPEWIRE=OFF -DSDL_JACK=OFF \
      -DSDL_SNDIO=OFF -DSDL_OSS=OFF -DSDL_X11=ON -DSDL_X11_XSCRNSAVER=OFF \
      -DSDL_X11_XTEST=OFF -DSDL_FRIBIDI=OFF -DSDL_LIBTHAI=OFF -DSDL_WAYLAND=ON \
      -DSDL_WAYLAND_LIBDECOR=OFF -DSDL_KMSDRM=OFF -DSDL_OPENVR=OFF -DSDL_RPI=OFF \
      -DSDL_ROCKCHIP=OFF -DSDL_VIVANTE=OFF -DSDL_OPENGL=ON -DSDL_OPENGLES=ON \
      -DSDL_VULKAN=ON -DSDL_DBUS=OFF -DSDL_IBUS=OFF -DSDL_LIBUDEV=OFF \
      -DSDL_LIBURING=OFF -DSDL_HIDAPI_LIBUSB=OFF
    diff <(grep '^#define' build/include-config-release/build_config/SDL_build_config.h | sort) \
         <(grep '^#define' "$(bazel cquery --output=files @sdl3//:config_h)" | sort)

Three differences are expected. CMake finds Mesa's `GL/glx.h` and sets
`SDL_VIDEO_OPENGL_GLX`; this module has no GLX. CMake sets the
`SDL_DISABLE_<intrinsics>` lines for the CPU of the machine that runs it;
this module leaves them to `SDL_intrin.h`. CMake reads the packages on the
machine for the xkbcommon and libdecor version macros; this file sets a
minimum runtime version.
"""

load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")

# What CMake puts in front of every probe on Linux: _GNU_SOURCE for the
# whole libc, _REENTRANT from the pthread check.
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L124
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/cmake/sdlchecks.cmake#L967-L969
_PROBE_COPTS = [
    "-D_GNU_SOURCE=1",
    "-D_REENTRANT",
]

def _define_name(prefix, text):
    # float.h -> HAVE_FLOAT_H, sys/types.h -> HAVE_SYS_TYPES_H, _Exit -> HAVE__EXIT:
    # the spelling CMake's string(TOUPPER) plus [./] -> _ produces.
    return prefix + text.upper().replace(".", "_").replace("/", "_")

def _header(header):
    return checks.AC_CHECK_HEADER(
        header,
        copts = _PROBE_COPTS,
        define = _define_name("HAVE_", header),
    )

def _includes(headers):
    # `includes` takes preprocessor lines, not header names.
    return ["#include <%s>" % header for header in headers]

def _builds(define, code, copts = [], linkopts = [], requires = None):
    # Defines `define` only on success: SDL reads these with #ifdef, so a
    # `#define HAVE_X 0` on failure would count as present.
    return checks.AC_TRY_LINK(
        code = code,
        copts = _PROBE_COPTS + copts,
        define = define,
        if_false = None,
        linkopts = linkopts,
        requires = requires,
    )

def _decl(symbol, headers):
    # CMake's check_symbol_exists: a macro passes, a function has to link.
    # CMake links libm into these probes.
    # https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1107-L1119
    return _builds(
        _define_name("HAVE_", symbol),
        "\n".join(_includes(headers)) + """
int main(void) {
#ifndef %s
    (void)%s;
#endif
    return 0;
}
""" % (symbol, symbol),
        linkopts = ["-lm"],
    )

# =============================================================================
# C library
# =============================================================================

# https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1046-L1076
_LIBC_HEADERS = [
    "float.h",
    "iconv.h",
    "inttypes.h",
    "limits.h",
    "malloc.h",
    "math.h",
    "memory.h",
    "signal.h",
    "stdarg.h",
    "stdbool.h",
    "stddef.h",
    "stdint.h",
    "stdio.h",
    "stdlib.h",
    "string.h",
    "strings.h",
    "sys/types.h",
    "time.h",
    "wchar.h",
]

# CMake probes each symbol against every header found above; here each one is
# probed with the header that declares it. The MSVC names are upstream's list.
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1078-L1119
_LIBC_SYMBOLS = {
    "math.h": [
        "acos",
        "acosf",
        "asin",
        "asinf",
        "atan",
        "atan2",
        "atan2f",
        "atanf",
        "ceil",
        "ceilf",
        "copysign",
        "copysignf",
        "cos",
        "cosf",
        "exp",
        "expf",
        "fabs",
        "fabsf",
        "floor",
        "floorf",
        "fmod",
        "fmodf",
        "log",
        "log10",
        "log10f",
        "logf",
        "lround",
        "lroundf",
        "modf",
        "modff",
        "pow",
        "powf",
        "round",
        "roundf",
        "scalbn",
        "scalbnf",
        "sin",
        "sinf",
        "sqr",
        "sqrt",
        "sqrtf",
        "tan",
        "tanf",
        "trunc",
        "truncf",
    ],
    "stdio.h": [
        "fopen64",
        "fseeko",
        "fseeko64",
        "sscanf",
        "vsnprintf",
        "vsscanf",
    ],
    "stdlib.h": [
        "_Exit",
        "_i64toa",
        "_ltoa",
        "abs",
        "atof",
        "atoi",
        "getenv",
        "itoa",
        "malloc",
        "putenv",
        "setenv",
        "strtod",
        "strtol",
        "strtoll",
        "strtoul",
        "strtoull",
        "unsetenv",
    ],
    "string.h": [
        "memcmp",
        "memcpy",
        "memmove",
        "memset",
        "strcasestr",
        "strchr",
        "strcmp",
        "strlcat",
        "strlcpy",
        "strlen",
        "strncmp",
        "strnlen",
        "strnstr",
        "strpbrk",
        "strrchr",
        "strstr",
        "strtok_r",
    ],
    "strings.h": [
        "bcopy",
        "index",
        "rindex",
    ],
    "wchar.h": [
        "wcscmp",
        "wcsdup",
        "wcslcat",
        "wcslcpy",
        "wcslen",
        "wcsncmp",
        "wcsnlen",
        "wcsstr",
        "wcstol",
    ],
}

# isinf/isnan: whether the double and float forms compile with float
# conversions as errors, and whether the f-suffixed functions exist.
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1121-L1158
_FLOAT_CLASS_COPTS = [
    "-Wfloat-conversion",
    "-Werror",
]

def _float_class_checks(fn):
    upper = fn.upper()
    return [
        _builds(
            "HAVE_" + upper,
            "#include <math.h>\nint main(void) { double d = 3.14159; return %s(d); }\n" % fn,
            copts = _FLOAT_CLASS_COPTS,
        ),
        _builds(
            "HAVE_%s_FLOAT_MACRO" % upper,
            "#include <math.h>\nint main(void) { float f = 3.14159f; return %s(f); }\n" % fn,
            copts = _FLOAT_CLASS_COPTS,
        ),
        _builds(
            "HAVE_%sF" % upper,
            "#include <math.h>\nint main(void) { float f = 3.14159f; return %sf(f); }\n" % fn,
            copts = _FLOAT_CLASS_COPTS,
        ),
    ]

# https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1160-L1182
_UNIX_SYMBOLS = [
    ("fdatasync", ["unistd.h"]),
    ("gethostname", ["unistd.h"]),
    ("getpagesize", ["unistd.h"]),
    ("getresgid", ["unistd.h"]),
    ("getresuid", ["unistd.h"]),
    ("sigaction", ["signal.h"]),
    ("sigtimedwait", ["signal.h"]),
    ("setjmp", ["setjmp.h"]),
    ("nanosleep", ["time.h"]),
    ("gmtime_r", ["time.h"]),
    ("localtime_r", ["time.h"]),
    ("nl_langinfo", ["langinfo.h"]),
    ("sysconf", ["unistd.h"]),
    ("sysctlbyname", ["sys/types.h", "sys/sysctl.h"]),
    ("getauxval", ["sys/auxv.h"]),
    ("elf_aux_info", ["sys/auxv.h"]),
    ("ppoll", ["poll.h"]),
    ("memfd_create", ["sys/mman.h"]),
    ("posix_fallocate", ["fcntl.h"]),
    ("posix_spawn_file_actions_addchdir", ["spawn.h"]),
    ("posix_spawn_file_actions_addchdir_np", ["spawn.h"]),
]

SDL3_CONFIG_CHECKS_LIBC = [
    # https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1043-L1045
    checks.AC_DEFINE("HAVE_LIBC", "1"),
] + [
    _header(header)
    for header in _LIBC_HEADERS
] + [
    _decl(symbol, [header])
    for header, symbols in _LIBC_SYMBOLS.items()
    for symbol in symbols
] + _float_class_checks("isinf") + _float_class_checks("isnan") + [
    _decl(symbol, headers)
    for symbol, headers in _UNIX_SYMBOLS
] + [
    # iconv from the C library; libiconv is not probed.
    # https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1183-L1210
    checks.AC_TRY_LINK(
        code = "#define LIBICONV_PLUG 1\n#include <stddef.h>\n#include <iconv.h>\nint main(void) { return !iconv_open(NULL, NULL); }\n",
        copts = _PROBE_COPTS,
        define = "HAVE_ICONV",
    ),
    # https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1212-L1213
    checks.AC_CHECK_MEMBER(
        "struct sigaction.sa_sigaction",
        copts = _PROBE_COPTS,
        define = "HAVE_SA_SIGACTION",
        includes = _includes(["signal.h"]),
    ),
    checks.AC_CHECK_MEMBER(
        "struct stat.st_mtim",
        copts = _PROBE_COPTS,
        define = "HAVE_ST_MTIM",
        includes = _includes(["sys/stat.h"]),
    ),
    # SDL_DISABLE_ALLOCA is MSVC-only, so it is never set here.
    # https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1025-L1040
    _header("alloca.h"),
]

# =============================================================================
# Compiler
# =============================================================================

# https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L618-L640
SDL3_CONFIG_CHECKS_COMPILER = [
    _builds(
        "HAVE_GCC_ATOMICS",
        """int main(int argc, char **argv) {
    int a;
    void *x, *y, *z;
    __sync_lock_test_and_set(&a, 4);
    __sync_lock_test_and_set(&x, y);
    __sync_fetch_and_add(&a, 1);
    __sync_bool_compare_and_swap(&a, 5, 10);
    __sync_bool_compare_and_swap(&x, y, z);
    return 0; }
""",
    ),
    _builds(
        "HAVE_GCC_SYNC_LOCK_TEST_AND_SET",
        """int main(int argc, char **argv) {
    int a;
    __sync_lock_test_and_set(&a, 1);
    __sync_lock_release(&a);
    return 0; }
""",
        requires = ["!HAVE_GCC_ATOMICS"],
    ),
]

# =============================================================================
# Linux
# =============================================================================

# CMake adds -D_REENTRANT -pthread to every probe here.
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/cmake/sdlchecks.cmake#L967-L969
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/cmake/sdlchecks.cmake#L1020-L1088
_PTHREAD = {
    "copts": ["-pthread"],
    "linkopts": ["-pthread"],
}

_PTHREAD_CHECKS = [
    _builds(
        "HAVE_PTHREADS",
        "#include <pthread.h>\nint main(void) { pthread_attr_t type; pthread_attr_init(&type); return 0; }\n",
        **_PTHREAD
    ),
    checks.AC_DEFINE("SDL_THREAD_PTHREAD", "1", requires = ["HAVE_PTHREADS"]),
    _builds(
        "SDL_THREAD_PTHREAD_RECURSIVE_MUTEX",
        "#include <pthread.h>\nint main(void) { pthread_mutexattr_t attr; pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE); return 0; }\n",
        requires = ["HAVE_PTHREADS"],
        **_PTHREAD
    ),
    _builds(
        "SDL_THREAD_PTHREAD_RECURSIVE_MUTEX_NP",
        "#include <pthread.h>\nint main(void) { pthread_mutexattr_t attr; pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE_NP); return 0; }\n",
        requires = [
            "HAVE_PTHREADS",
            "!SDL_THREAD_PTHREAD_RECURSIVE_MUTEX",
        ],
        **_PTHREAD
    ),
    _builds(
        "HAVE_PTHREADS_SEM",
        "#include <pthread.h>\n#include <semaphore.h>\nint main(void) { return 0; }\n",
        requires = ["HAVE_PTHREADS"],
        **_PTHREAD
    ),
    _builds(
        "HAVE_SEM_TIMEDWAIT",
        "#include <pthread.h>\n#include <semaphore.h>\nint main(void) { sem_timedwait(NULL, NULL); return 0; }\n",
        requires = ["HAVE_PTHREADS_SEM"],
        **_PTHREAD
    ),
    _header("pthread.h"),
    _header("pthread_np.h"),
    _builds(
        "HAVE_PTHREAD_SETNAME_NP",
        """#include <pthread.h>
int main(void) {
#ifdef __APPLE__
    pthread_setname_np("");
#else
    pthread_setname_np(pthread_self(), "");
#endif
    return 0; }
""",
        requires = ["HAVE_PTHREAD_H"],
        **_PTHREAD
    ),
    checks.AC_CHECK_DECL(
        "pthread_set_name_np",
        copts = _PROBE_COPTS,
        define = "HAVE_PTHREAD_SET_NAME_NP",
        includes = _includes([
            "pthread.h",
            "pthread_np.h",
        ]),
        requires = ["HAVE_PTHREAD_NP_H"],
    ),
]

# https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1850-L1941
_LINUX_INPUT_CHECKS = [
    _builds(
        "HAVE_LINUX_INPUT_H",
        "#include <linux/input.h>\n#ifndef EVIOCGNAME\n#error EVIOCGNAME() ioctl not available\n#endif\nint main(void) { return 0; }\n",
    ),
    _builds(
        "HAVE_INPUT_KD",
        """#include <linux/kd.h>
#include <linux/keyboard.h>
#include <sys/ioctl.h>
int main(void) {
    struct kbentry kbe;
    kbe.kb_table = KG_CTRL;
    ioctl(0, KDGKBENT, &kbe);
    return 0; }
""",
    ),
    _builds(
        "HAVE_LINUX_VIDEODEV2_H",
        "#include <linux/videodev2.h>\nint main(void) { return 0; }\n",
    ),
    checks.AC_DEFINE("SDL_INPUT_LINUXEV", "1", requires = ["HAVE_LINUX_INPUT_H"]),
    checks.AC_DEFINE("SDL_INPUT_LINUXKD", "1", requires = ["HAVE_INPUT_KD"]),
    checks.AC_DEFINE("SDL_HAPTIC_LINUX", "1", requires = ["HAVE_LINUX_INPUT_H"]),
    checks.AC_DEFINE("SDL_JOYSTICK_LINUX", "1", requires = ["HAVE_LINUX_INPUT_H"]),
    checks.AC_DEFINE("SDL_CAMERA_DRIVER_V4L2", "1", requires = ["HAVE_LINUX_VIDEODEV2_H"]),
    _header("sys/inotify.h"),
    _decl("inotify_init", ["sys/inotify.h"]),
    _decl("inotify_init1", ["sys/inotify.h"]),
    checks.AC_DEFINE("HAVE_INOTIFY", "1", requires = [
        "HAVE_SYS_INOTIFY_H",
        "HAVE_INOTIFY_INIT",
    ]),
]

# https://github.com/libsdl-org/SDL/blob/release-3.4.16/cmake/sdlchecks.cmake#L52-L72
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1375-L1391
_UNIX_CHECKS = [
    _decl("dlopen", ["dlfcn.h"]),
    checks.AC_DEFINE("SDL_LOADSO_DLOPEN", "1", requires = ["HAVE_DLOPEN"]),
    checks.AC_DEFINE("DYNAPI_NEEDS_DLOPEN", "1"),
    _builds(
        "HAVE_O_CLOEXEC",
        "#include <fcntl.h>\nint flag = O_CLOEXEC;\nint main(void) { return 0; }\n",
    ),
    # https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L2085-L2096
    checks.AC_CHECK_FUNC("clock_gettime", copts = _PROBE_COPTS, define = "HAVE_CLOCK_GETTIME"),
    # https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L3472-L3519
    checks.AC_TRY_LINK(
        code = """#include <spawn.h>
#include <unistd.h>
int main(void) {
    int pipes[2];
    int pid;
    const char *args[] = { "/bin/false", NULL };
    const char *env[] = { NULL };
    pipe(pipes);
    posix_spawnattr_t attr;
    posix_spawn_file_actions_t fa;
    posix_spawnattr_init(&attr);
    posix_spawn_file_actions_init(&fa);
    posix_spawn_file_actions_addclose(&fa, pipes[0]);
    posix_spawn_file_actions_adddup2(&fa, pipes[1], STDOUT_FILENO);
    posix_spawn(&pid, args[0], &fa, &attr, (char *const *)args, (char *const *)env);
    posix_spawnp(&pid, args[0], &fa, &attr, (char *const *)args, (char *const *)env);
    posix_spawn_file_actions_destroy(&fa);
    posix_spawnattr_destroy(&attr);
    return 0; }
""",
        copts = _PROBE_COPTS,
        define = "HAVE_POSIX_SPAWN",
    ),
    _decl("vfork", ["unistd.h"]),
    checks.AC_DEFINE("SDL_PROCESS_POSIX", "1", requires = [
        "HAVE_POSIX_SPAWN",
        "HAVE_VFORK",
    ]),
]

# Subsystems whose CMake answer on Linux follows from the build options this
# module fixes (the Bazel equivalents of the -DSDL_*=ON/OFF choices).
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/CMakeLists.txt#L1774-L2137
_LINUX_FIXED = [
    # Audio: ALSA loaded at runtime; PulseAudio, PipeWire, JACK, sndio, OSS off.
    # https://github.com/libsdl-org/SDL/blob/release-3.4.16/cmake/sdlchecks.cmake#L100-L135
    checks.AC_DEFINE("SDL_AUDIO_DRIVER_ALSA", "1"),
    checks.AC_DEFINE("SDL_AUDIO_DRIVER_ALSA_DYNAMIC", '"libasound.so.2"'),
    checks.AC_DEFINE("SDL_AUDIO_DRIVER_DISK", "1"),
    checks.AC_DEFINE("SDL_AUDIO_DRIVER_DUMMY", "1"),
    # Joysticks: HIDAPI without a backend (hidraw needs libudev, libusb is
    # off); CMake ties the virtual joystick to SDL_HIDAPI.
    # https://github.com/libsdl-org/SDL/blob/release-3.4.16/cmake/sdlchecks.cmake#L1248-L1307
    checks.AC_DEFINE("SDL_JOYSTICK_HIDAPI", "1"),
    checks.AC_DEFINE("SDL_JOYSTICK_VIRTUAL", "1"),
    checks.AC_DEFINE("SDL_SENSOR_DUMMY", "1"),
    checks.AC_DEFINE("SDL_POWER_LINUX", "1"),
    checks.AC_DEFINE("SDL_FILESYSTEM_UNIX", "1"),
    checks.AC_DEFINE("SDL_STORAGE_STEAM", "1"),
    checks.AC_DEFINE("SDL_FSOPS_POSIX", "1"),
    checks.AC_DEFINE("SDL_TIME_UNIX", "1"),
    checks.AC_DEFINE("SDL_TIMER_UNIX", "1"),
    checks.AC_DEFINE("SDL_CAMERA_DRIVER_DUMMY", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_DUMMY", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_OFFSCREEN", "1"),
    # OpenGL over EGL (no GLX: GL/glx.h is Mesa's, not a Bazel module),
    # GLES2 and Vulkan from the headers SDL vendors in src/video/khronos.
    # https://github.com/libsdl-org/SDL/blob/release-3.4.16/cmake/sdlchecks.cmake#L861-L937
    checks.AC_DEFINE("SDL_VIDEO_OPENGL", "1"),
    checks.AC_DEFINE("SDL_VIDEO_OPENGL_EGL", "1"),
    checks.AC_DEFINE("SDL_VIDEO_OPENGL_ES2", "1"),
    checks.AC_DEFINE("SDL_VIDEO_RENDER_OGL", "1"),
    checks.AC_DEFINE("SDL_VIDEO_RENDER_OGL_ES2", "1"),
    checks.AC_DEFINE("SDL_VIDEO_VULKAN", "1"),
    checks.AC_DEFINE("SDL_VIDEO_RENDER_VULKAN", "1"),
    checks.AC_DEFINE("SDL_GPU_VULKAN", "1"),
    checks.AC_DEFINE("SDL_VIDEO_RENDER_GPU", "1"),
]

# X11, loaded at runtime by soname; the headers are the modules in
# MODULE.bazel. Each extension macro makes SDL load that extension's symbols
# from the system library. The newest are from libXi 1.7 (2013), and a missing
# one turns off that extension only, not the X11 driver. Xscrnsaver and XTest
# have no Bazel module.
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/cmake/sdlchecks.cmake#L273-L564
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/src/video/x11/SDL_x11sym.h#L177-L184
_X11_FIXED = [
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_DYNAMIC", '"libX11.so.6"'),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_DYNAMIC_XCURSOR", '"libXcursor.so.1"'),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_DYNAMIC_XEXT", '"libXext.so.6"'),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_DYNAMIC_XFIXES", '"libXfixes.so.3"'),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_DYNAMIC_XINPUT2", '"libXi.so.6"'),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_DYNAMIC_XRANDR", '"libXrandr.so.2"'),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_HAS_XKBLIB", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_SUPPORTS_GENERIC_EVENTS", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_XCURSOR", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_XDBE", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_XFIXES", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_XINPUT2", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_XINPUT2_SUPPORTS_GESTURE", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_XINPUT2_SUPPORTS_MULTITOUCH", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_XINPUT2_SUPPORTS_SCROLLINFO", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_XRANDR", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_XSHAPE", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_X11_XSYNC", "1"),
]

# Wayland, loaded at runtime by soname; the protocol code is generated from
# the XML files SDL ships. No libdecor (no Bazel module).
# https://github.com/libsdl-org/SDL/blob/release-3.4.16/cmake/sdlchecks.cmake#L643-L763
_WAYLAND_FIXED = [
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_WAYLAND", "1"),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC", '"libwayland-client.so.0"'),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_CURSOR", '"libwayland-cursor.so.0"'),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_EGL", '"libwayland-egl.so.1"'),
    checks.AC_DEFINE("SDL_VIDEO_DRIVER_WAYLAND_DYNAMIC_XKBCOMMON", '"libxkbcommon.so.0"'),
]

SDL3_CONFIG_CHECKS_LINUX = (
    _PTHREAD_CHECKS +
    _LINUX_INPUT_CHECKS +
    _UNIX_CHECKS +
    _LINUX_FIXED +
    _X11_FIXED +
    _WAYLAND_FIXED
)
