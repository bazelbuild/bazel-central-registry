load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@openfhe_config//:config.bzl", "HAS_INT128", "MATHBACKEND")
load("@rules_cc//cc:defs.bzl", "cc_library", "cc_shared_library")

package(
    default_visibility = ["//visibility:public"],
    features = [
        "-layering_check",  # Incompatible with `#include "gtest/gtest.h"`
        "-use_header_modules",  # Incompatible with -fexceptions.
    ],
)

bool_flag(
    name = "enable_openmp",
    build_setting_default = True,
)

config_setting(
    name = "config_enable_openmp",
    flag_values = {":enable_openmp": "True"},
)

config_setting(
    name = "config_disable_openmp",
    flag_values = {":enable_openmp": "False"},
)

OPENFHE_VERSION = "1.4.2"

OPENFHE_DEFINES = [
    "MATHBACKEND=" + str(MATHBACKEND),
    "OPENFHE_VERSION=" + OPENFHE_VERSION,
] + select({
    "//:config_enable_openmp": ["PARALLEL"],
    "//conditions:default": [],
})

OPENFHE_COPTS = [
    "-Wno-non-virtual-dtor",
    "-Wno-shift-op-parentheses",
    "-Wno-unused-private-field",
    "-fexceptions",
]

config_setting(
    name = "clang_openmp",
    flag_values = {
        "@rules_cc//cc/compiler:compiler": "clang",
        "//:enable_openmp": "True",
    },
)

config_setting(
    name = "gcc_openmp",
    flag_values = {
        "@rules_cc//cc/compiler:compiler": "gcc",
        "//:enable_openmp": "True",
    },
)

_OPENMP_CLANG_LINKOPTS = [
    "-fopenmp",
    "-lomp",
]

_OPENMP_GCC_LINKOPTS = [
    "-fopenmp",
    "-lgomp",
]

OPENMP_LINKOPTS = select({
    "//:clang_openmp": _OPENMP_CLANG_LINKOPTS,
    "//:gcc_openmp": _OPENMP_GCC_LINKOPTS,
    "//conditions:default": [],
})

OPENMP_COPTS = select({
    "//:config_enable_openmp": [
        "-fopenmp",
        "-Xpreprocessor",
        "-Wno-unused-command-line-argument",
    ],
    "//conditions:default": [],
})

genrule(
    name = "generate_config_core_h",
    outs = ["src/core/include/config_core.h"],
    cmd = "$(location @openfhe_config//:generate_header.sh) $@",
    tools = ["@openfhe_config//:generate_header.sh"],
)

filegroup(
    name = "headers",
    srcs = [":generate_config_core_h"] + glob([
        "src/binfhe/include/*.h",
        "src/core/include/**/*.h",
        "src/pke/include/**/*.h",
    ]),
)

cc_library(
    name = "core",
    srcs = [":generate_config_core_h"] + glob([
        "src/core/lib/**/*.c",
        "src/core/lib/**/*.cpp",
    ]),
    copts = OPENFHE_COPTS + OPENMP_COPTS + [
        # /utils/blockAllocator/blockAllocator.cpp has misaligned-pointer-use
        "-fno-sanitize=alignment",
    ],
    defines = OPENFHE_DEFINES,
    includes = [
        "src/core/include",
        "src/core/lib",
    ],
    linkopts = OPENMP_LINKOPTS,
    linkstatic = True,
    textual_hdrs = [":generate_config_core_h"] + glob([
        "src/core/include/**/*.h",
        "src/core/lib/**/*.cpp",
    ]),
    deps = [
        ":generate_config_core_h",
        "@cereal",
    ],
)

cc_library(
    name = "binfhe",
    srcs = [":generate_config_core_h"] + glob([
        "src/binfhe/lib/**/*.cpp",
    ]),
    copts = OPENFHE_COPTS + OPENMP_COPTS,
    defines = OPENFHE_DEFINES,
    includes = [
        "src/binfhe/include",
        "src/binfhe/lib",
    ],
    linkopts = OPENMP_LINKOPTS,
    linkstatic = True,
    textual_hdrs = [":generate_config_core_h"] + glob(["src/binfhe/include/**/*.h"]),
    deps = [
        ":core",
        ":generate_config_core_h",
    ],
)

cc_library(
    name = "pke",
    srcs = [":generate_config_core_h"] + glob([
        "src/pke/lib/**/*.cpp",
    ]),
    copts = OPENFHE_COPTS + OPENMP_COPTS + [
        "-Wno-vla-extension",
    ],
    defines = OPENFHE_DEFINES,
    includes = [
        "src/pke/include",
        "src/pke/lib",
    ],
    linkopts = OPENMP_LINKOPTS,
    linkstatic = True,
    textual_hdrs = [":generate_config_core_h"] + glob([
        "src/pke/include/**/*.h",
        "src/pke/lib/**/*.cpp",
    ]),
    deps = [
        ":binfhe",
        ":core",
        ":generate_config_core_h",
        "@cereal",
    ],
)

# Generates a shared library that can be shipped with the python frontend.
cc_shared_library(
    name = "libopenfhe",
    shared_lib_name = "libopenfhe.so",
    deps = [
        ":binfhe",
        ":core",
        ":pke",
    ],
)

alias(
    name = "openfhe",
    actual = ":pke",
)
