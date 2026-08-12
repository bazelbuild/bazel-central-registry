"""Test generation for the runnable upstream Boost.SafeNumerics tests."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, srcs):
    tests = []
    for src in srcs:
        test_name = src.removeprefix("test_").removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + native.glob(["*.hpp"]),
            deps = [
                "@boost.config",
                "@boost.core",
                "@boost.integer",
                "@boost.logic",
                "@boost.mp11",
                "@boost.multiprecision",
                "@boost.rational",
                "@boost.safe_numerics",
            ],
        )
    native.test_suite(name = name, tests = tests)
