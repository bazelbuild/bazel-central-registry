"""Test generation for the upstream Boost.Convert suite."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, srcs):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources that define their own main.
    """
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp").replace("-", "_")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + native.glob(["*.hpp"]),
            deps = [
                "@boost.convert",
                "@boost.detail",
                "@boost.lexical_cast",
                "@boost.random",
                "@boost.test",
                "@boost.utility",
            ],
        )
    native.test_suite(name = name, tests = tests)
