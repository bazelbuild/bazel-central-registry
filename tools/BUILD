load("@rules_python//python:defs.bzl", "py_binary")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")
load("@tools_deps//:requirements.bzl", "requirement")

compile_pip_requirements(
    name = "requirements",
    requirements_in = "requirements.in",
    requirements_txt = "requirements_lock.txt",
)

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
