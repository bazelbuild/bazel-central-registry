load("@pip//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_library", "py_test")

py_library(
    name = "prepare_context",
    srcs = ["prepare_context.py"],
    imports = ["."],
    deps = [
        requirement("pyyaml"),
    ],
)

py_library(
    name = "post_review",
    srcs = ["post_review.py"],
    imports = ["."],
)

py_test(
    name = "prepare_context_test",
    size = "small",
    srcs = ["prepare_context_test.py"],
    legacy_create_init = 0,
    deps = [
        ":prepare_context",
    ],
)

py_test(
    name = "post_review_test",
    size = "small",
    srcs = ["post_review_test.py"],
    legacy_create_init = 0,
    deps = [
        ":post_review",
    ],
)
