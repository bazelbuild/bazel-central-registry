load("@rules_python//python:defs.bzl", "py_binary")
load("@tools_deps//:requirements.bzl", "requirement")

py_binary(
    name = "add_module",
    srcs = ["add_module.py"],
    deps = [
        requirement("pyyaml"),
    ],
)

py_test(
    name = "verify_stable_archives",
    srcs = [
        "verify_stable_archives.py",
    ],
    data = [
        "//:for_bazel_tests",
    ],
    deps = [
        requirement("pyyaml"),
    ],
)
