load("@rules_python//python:py_binary.bzl", "py_binary")

py_binary(
    name = "py_bin_1",
    srcs = ["py_bin_1.py"],
    deps = [
        "@my_deps_1//numpy",
        "@my_deps_1//mpmath",
    ],
)

py_binary(
    name = "py_bin_2",
    srcs = ["py_bin_2.py"],
    deps = [
        "@my_deps_2//attrs"
    ],
)

alias(
    name = "yamllint",
    actual = "@pypi_yamllint//:rules_python_wheel_entry_point_yamllint",
)
