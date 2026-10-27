load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_python//python:defs.bzl", "py_library")
load("@spconv_codegen_pip//:requirements.bzl", "requirement")

package(default_visibility = ["//visibility:public"])

py_library(
    name = "generator",
    srcs = glob(["cumm/**/*.py"]),
    data = glob([
        "cumm/**/*.so",
        "cumm/include/**",
    ]),
    imports = ["."],
    deps = [
        requirement("ccimport"),
        requirement("numpy"),
        requirement("pccm"),
        requirement("pybind11"),
        requirement("sympy"),
    ],
)

cc_library(
    name = "headers",
    hdrs = glob(["cumm/include/**"]),
    includes = ["cumm/include"],
)

filegroup(
    name = "license",
    srcs = glob(["*.dist-info/LICENSE"]),
)
