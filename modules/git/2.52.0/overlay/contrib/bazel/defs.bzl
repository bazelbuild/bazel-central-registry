_GIT_BASE_COPTS = [
    "-g",
    "-O2",
    "-Wall",
    "-I.",
    "-DUSE_CURL_FOR_IMAP_SEND",
    "-DSUPPORTS_SIMPLE_IPC",
    "-DSHA1_DC",
    "-DSHA1DC_NO_STANDARD_INCLUDES",
    "-DSHA1DC_INIT_SAFE_HASH_DEFAULT=0",
    '-DSHA1DC_CUSTOM_INCLUDE_SHA1_C=\\"git-compat-util.h\\"',
    '-DSHA1DC_CUSTOM_INCLUDE_UBC_CHECK_C=\\"git-compat-util.h\\"',
    "-DSHA256_BLK",
    '-DSHELL_PATH=\\"/bin/sh\\"',
    '-DGIT_HTML_PATH=\\"share/doc/git-doc\\"',
    '-DGIT_MAN_PATH=\\"share/man\\"',
    '-DGIT_INFO_PATH=\\"share/info\\"',
    '-DGIT_EXEC_PATH=\\"libexec/git-core\\"',
    '-DGIT_LOCALE_PATH=\\"share/locale\\"',
    '-DBINDIR=\\"bin\\"',
    '-DFALLBACK_RUNTIME_PREFIX=\\"\\"',
    '-DDEFAULT_GIT_TEMPLATE_DIR=\\"share/git-core/templates\\"',
    '-DETC_GITCONFIG=\\"etc/gitconfig\\"',
    '-DETC_GITATTRIBUTES=\\"etc/gitattributes\\"',
    '-DPAGER_ENV=\\"LESS=FRX\\040LV=-c\\"',
    "-DNO_GETTEXT",
]

_GIT_CPU_DEFINES = select({
    "@platforms//cpu:aarch64": ['-DGIT_HOST_CPU=\\"aarch64\\"'],
    "@platforms//cpu:arm64": ['-DGIT_HOST_CPU=\\"aarch64\\"'],
    "@platforms//cpu:x86_64": ['-DGIT_HOST_CPU=\\"x86_64\\"'],
    "//conditions:default": ['-DGIT_HOST_CPU=\\"unknown\\"'],
})

_GIT_OS_DEFINES = select({
    "@platforms//os:linux": [
        "-DHAVE_ALLOCA_H",
        "-DHAVE_PATHS_H",
        "-DHAVE_DEV_TTY",
        "-DHAVE_CLOCK_GETTIME",
        "-DHAVE_CLOCK_MONOTONIC",
        "-DHAVE_SYNC_FILE_RANGE",
        "-DHAVE_SYSINFO",
        "-DHAVE_GETDELIM",
        "-DHAVE_GETRANDOM",
        "-DFREAD_READS_DIRECTORIES",
        "-DNO_STRLCPY",
        "-DNO_ICONV",
    ],
    "@platforms//os:macos": [
        "-DHAVE_PATHS_H",
        "-DHAVE_DEV_TTY",
        "-DHAVE_GETDELIM",
        "-DFREAD_READS_DIRECTORIES",
        "-DNO_MEMMEM",
        "-DUSE_ST_TIMESPEC",
        "-DPRECOMPOSE_UNICODE",
        "-DPROTECT_HFS_DEFAULT=1",
        "-DHAVE_BSD_SYSCTL",
        "-DHAVE_NS_GET_EXECUTABLE_PATH",
        "-DUSE_ENHANCED_BASIC_REGULAR_EXPRESSIONS",
        "-DHAVE_ARC4RANDOM",
        # fsmonitor
        "-DHAVE_FSMONITOR_DAEMON_BACKEND",
        "-DHAVE_FSMONITOR_OS_SETTINGS",
    ],
    "@platforms//os:windows": [
        # fsmonitor
        "-DHAVE_FSMONITOR_DAEMON_BACKEND",
        "-DHAVE_FSMONITOR_OS_SETTINGS",
        "-DNO_ICONV",
    ],
    "//conditions:default": [],
})

GIT_COPTS = _GIT_BASE_COPTS + _GIT_CPU_DEFINES + _GIT_OS_DEFINES

GIT_LINKOPTS = ["-lpthread"] + select({
    "@platforms//os:macos": [
        "-framework",
        "CoreServices",
        # TODO(sluongng): Use libiconv when it's available of BCR
        "-liconv",
    ],
    "//conditions:default": [],
})
