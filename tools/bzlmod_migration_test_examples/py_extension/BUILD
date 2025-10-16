load("@rules_python//python:py_binary.bzl", "py_binary")
load("@rules_python//python:py_runtime.bzl", "py_runtime")

py_binary(
    name = "py_bin",
    srcs = ["py_bin.py"],
    deps = [
        "@my_deps_1//numpy",
        "@my_deps_1//mpmath",
        "@my_deps_2//mpmath"
    ],
)

py_runtime(
    name = "py3_runtime_11_1",
    interpreter = "@python_3_11_x86_64-unknown-linux-gnu//:bin/python3",
    python_version = "PY3",
)

py_runtime(
    name = "py3_runtime_11_2",
    interpreter = "@python_3_11_aarch64-unknown-linux-gnu//:bin/python3",
    python_version = "PY3",
)

py_runtime(
    name = "py3_runtime_12",
    interpreter = "@python_3_12_x86_64-unknown-linux-gnu//:bin/python3",
    python_version = "PY3",
)
