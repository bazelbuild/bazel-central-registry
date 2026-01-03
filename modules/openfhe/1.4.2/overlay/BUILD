load("@rules_cc//cc:defs.bzl", "cc_library", "cc_shared_library")
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@openfhe_config//:config.bzl", "MATHBACKEND", "HAS_INT128")


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

_OPENFHE_LINKOPTS = [
    "-fopenmp",
    "-lomp",
]

_OPENMP_COPTS = [
    "-fopenmp",
    "-Xpreprocessor",
    "-Wno-unused-command-line-argument",
]

MAYBE_OPENFHE_LINKOPTS = select({
    "//:config_enable_openmp": _OPENFHE_LINKOPTS,
    "//conditions:default": [],
})

MAYBE_OPENMP_COPTS = select({
    "//:config_enable_openmp": _OPENMP_COPTS,
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
    copts = OPENFHE_COPTS + MAYBE_OPENMP_COPTS + [
        # /utils/blockAllocator/blockAllocator.cpp has misaligned-pointer-use
        "-fno-sanitize=alignment",
    ],
    defines = OPENFHE_DEFINES,
    includes = [
        "src/core/include",
        "src/core/lib",
    ],
    linkopts = MAYBE_OPENFHE_LINKOPTS,
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
    copts = OPENFHE_COPTS + MAYBE_OPENMP_COPTS,
    defines = OPENFHE_DEFINES,
    includes = [
        "src/binfhe/include",
        "src/binfhe/lib",
    ],
    linkopts = MAYBE_OPENFHE_LINKOPTS,
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
    copts = OPENFHE_COPTS + MAYBE_OPENMP_COPTS + [
        "-Wno-vla-extension",
    ],
    defines = OPENFHE_DEFINES,
    includes = [
        "src/pke/include",
        "src/pke/lib",
    ],
    linkopts = MAYBE_OPENFHE_LINKOPTS,
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
