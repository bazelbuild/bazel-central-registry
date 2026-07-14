"""Macro for common nanobind test layout."""

load("@nanobind_test_pip_deps//:requirements.bzl", "requirement")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_shared_library.bzl", "cc_shared_library")
load("@rules_python//python:defs.bzl", "py_test")

visibility("private")

def nb_test(name):
    cc_library(
        name = name + "_lib",
        srcs = ["test_{}.cpp".format(name)],
        deps = [
            "//:nanobind",
            ":inter_module",  # NOTE: Not all targets need this
        ],
        target_compatible_with = select({
            "@platforms//os:windows": [
                # TODO: Windows fails to link python libs
                "@platforms//:incompatible",
            ],
            "//conditions:default": [],
        }),
        copts = select({
            "@rules_cc//cc/compiler:msvc-cl": ["/std:c++17"],
            "//conditions:default": ["--std=c++17"],
        }),
    )

    cc_shared_library(
        name = name + "_ext",
        deps = [":" + name + "_lib"],
        shared_lib_name = "test_{}_ext.so".format(name),
    )

    py_test(
        name = "test_" + name,
        srcs = [
            "test_{}.py".format(name),
            "bazel_pytest_main.py",
        ],
        main = "bazel_pytest_main.py",
        args = [native.package_name() + "/test_{}.py".format(name)],
        imports = ["."],
        data = [
            ":" + name + "_ext",
        ],
        deps = [
            ":common",  # NOTE: Not all targets need this
            requirement("pytest"),
        ],
    )
