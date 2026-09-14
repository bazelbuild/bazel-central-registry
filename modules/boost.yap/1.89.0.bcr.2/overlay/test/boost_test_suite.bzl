"""Test generation for the upstream Boost.YAP suite."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

DEPS = [
    "@boost.core",
    "@boost.mpl",
    "@boost.yap",
]

def boost_test_suite(name, srcs, copts = []):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources that define their own main.
        copts: extra compiler options for these tests.
    """
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src],
            copts = copts,
            deps = DEPS,
        )
    native.test_suite(name = name, tests = tests)
