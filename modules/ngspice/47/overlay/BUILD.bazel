load("@bazel_skylib//lib:selects.bzl", "selects")
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("//private:config.bzl", "ngspice_config")
load("//private:core.bzl", "ngspice_libraries")
load("//private:outputs.bzl", "linking_only", "openmp_header")
load("//private:runtime.bzl", "ngspice_launcher", "ngspice_runtime")
load("//private:xspice.bzl", "ngspice_code_models", "ngspice_cosimulation_modules")

package(default_visibility = ["//visibility:private"])

exports_files(["COPYING"])

bool_flag(
    name = "xspice",
    build_setting_default = True,
    visibility = ["//visibility:public"],
)

bool_flag(
    name = "openmp",
    build_setting_default = True,
    visibility = ["//visibility:public"],
)

config_setting(
    name = "with_xspice",
    flag_values = {":xspice": "true"},
)

config_setting(
    name = "with_openmp",
    flag_values = {":openmp": "true"},
)

selects.config_setting_group(
    name = "clang_openmp",
    match_all = [
        ":with_openmp",
        "@rules_cc//cc/compiler:clang",
    ],
)

selects.config_setting_group(
    name = "gcc_openmp",
    match_all = [
        ":with_openmp",
        "@rules_cc//cc/compiler:gcc",
    ],
)

# GCC uses its toolchain's omp.h and libgomp. Clang uses the declared LLVM
# runtime; its header is an implementation dependency and cannot leak to users.
openmp_header(
    name = "openmp_header",
    dep = "@openmp",
)

linking_only(
    name = "llvm_openmp_runtime",
    dep = "@openmp",
)

cc_library(
    name = "openmp_runtime",
    linkopts = select({
        "@rules_cc//cc/compiler:clang": [],
        "@rules_cc//cc/compiler:gcc": ["-fopenmp"],
    }),
    deps = select({
        "@rules_cc//cc/compiler:clang": [":llvm_openmp_runtime"],
        "@rules_cc//cc/compiler:gcc": [],
    }),
)

SUPPORTED_PLATFORMS = select({
    "@platforms//os:linux": [],
    "@platforms//os:macos": [],
    "//conditions:default": ["@platforms//:incompatible"],
})

ngspice_config(name = "config")

ngspice_libraries(
    name = "ngspice",
    target_compatible_with = SUPPORTED_PLATFORMS,
)

ngspice_code_models(
    name = "code_models",
    config = ":config",
    target_compatible_with = SUPPORTED_PLATFORMS,
)

ngspice_cosimulation_modules(
    name = "cosimulation_modules",
    config = ":config",
    target_compatible_with = SUPPORTED_PLATFORMS,
)

ngspice_runtime(
    name = "runtime",
    code_models = select({
        ":with_xspice": [":code_models"],
        "//conditions:default": [],
    }),
    cosimulation_modules = select({
        ":with_xspice": [":cosimulation_modules"],
        "//conditions:default": [],
    }),
    target_compatible_with = SUPPORTED_PLATFORMS,
    visibility = ["//visibility:public"],
    xspice = select({
        ":with_xspice": True,
        "//conditions:default": False,
    }),
)

ngspice_runtime(
    name = "cli_runtime",
    cli = ":cli_native",
    code_models = select({
        ":with_xspice": [":code_models"],
        "//conditions:default": [],
    }),
    cosimulation_modules = select({
        ":with_xspice": [":cosimulation_modules"],
        "//conditions:default": [],
    }),
    target_compatible_with = SUPPORTED_PLATFORMS,
    xspice = select({
        ":with_xspice": True,
        "//conditions:default": False,
    }),
)

ngspice_launcher(
    name = "cli_launcher",
    runtime = ":cli_runtime",
)

sh_binary(
    name = "ngspice_bin",
    srcs = [":cli_launcher"],
    data = [":cli_runtime"],
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
