load("@rules_python//python:pip.bzl", "compile_pip_requirements")

compile_pip_requirements(
    name = "requirements",
    requirements_txt = "requirements_lock.txt",
)

filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["modules/**"]),
    visibility = [
        "//:__subpackages__",
    ],
)
