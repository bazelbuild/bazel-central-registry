load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

bool_flag(
    name = "threadsafe",
    build_setting_default = False,
)

config_setting(
    name = "threadsafe_setting",
    flag_values = {":threadsafe": "True"},
)

filegroup(
    name = "headers",
    srcs = glob([
        "include/**/*.h",
        "include/**/*.hpp",
    ]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "cereal",
    hdrs = glob([
        "include/cereal/**/*.hpp",
        "include/cereal/**/*.h",
    ]),
    defines = select({
        ":threadsafe_setting": ["CEREAL_THREAD_SAFE=1"],
        "//conditions:default": [],
    }),
    includes = ["include"],
    visibility = ["//visibility:public"],
)
