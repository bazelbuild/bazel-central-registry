"""Wrapper around cc_test to add test main."""

load("@rules_cc//cc:defs.bzl", "cc_test")

def cpp_unittest(name, **kwargs):
    srcs = kwargs.pop("srcs", [])

    # Change the default to small.
    size = kwargs.pop("size", "small")
    deps = kwargs.pop("deps", [])

    cc_test(
        name = name,
        srcs = srcs,
        size = size,
        deps = deps + [
            "//folly/test/common:test_main_lib",
            "//folly/ext/buck2:test_ext",
        ],
        **kwargs
    )
