"""Test generation for the upstream Boost.Parser suite."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

COPTS = select({
    "@platforms//os:windows": [
        "/std:c++17",
        "/source-charset:utf-8",
        "/bigobj",
    ],
    "//conditions:default": ["-std=c++17"],
})

DEPS = [
    "@boost.charconv",
    "@boost.core",
    "@boost.optional",
    "@boost.parser",
    "@boost.variant",
    "@boost.variant2",
]

def boost_test_suite(name, srcs):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources that define their own main.
    """
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + native.glob(["*.hpp"]),
            copts = COPTS,
            deps = DEPS,
        )
    native.test_suite(name = name, tests = tests)
