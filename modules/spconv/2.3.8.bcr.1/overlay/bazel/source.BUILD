# Builds the inference-only source tree prepared by this module.
load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_cuda//cuda:defs.bzl", "cuda_library")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

filegroup(
    name = "licenses",
    srcs = [
        "CUMM-LICENSE",
        "SPCONV-LICENSE",
    ],
)

cc_library(
    name = "headers",
    hdrs = glob([
        "spconv/include/**/*.h",
        "spconv/include/**/*.hpp",
        "cumm/include/**/*.h",
        "cumm/include/**/*.hpp",
        "cumm/include/**/*.cuh",
    ]),
    defines = [
        "TV_CUDA",
        "TV_ENABLE_HARDWARE_ACC",
    ],
    includes = [
        "cumm/include",
        "spconv/include",
    ],
    deps = [
        "@cuda//:cublas",
        "@cuda//:cuda_runtime",
    ],
)

cuda_library(
    name = "kernels",
    srcs = glob(["spconv/src/**/*.cu"]),
    copts = [
        "-std=c++17",
        "-O3",
        "--extended-lambda",
    ],
    deps = [":headers"],
)

cc_library(
    name = "spconv",
    srcs = glob(["spconv/src/**/*.cc"]),
    copts = [
        "-O3",
        "-Wno-unused-variable",
        "-Wno-unused-but-set-variable",
        "-Wno-error=reorder",
    ],
    linkstatic = True,
    deps = [
        ":headers",
        ":kernels",
    ],
    # Generated CUDA objects call back into this host object group.
    alwayslink = True,
)
