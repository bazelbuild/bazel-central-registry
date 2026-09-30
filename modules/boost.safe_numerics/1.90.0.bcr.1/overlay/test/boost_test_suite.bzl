"""Test generation for the runnable upstream Boost.SafeNumerics tests."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, srcs, target_compatible_with = []):
    tests = []
    for src in srcs:
        test_name = src.removeprefix("test_").removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + native.glob(["*.hpp"]),
            copts = select({
                # MSVC needs conformance mode for the SFINAE in
                # boost/safe_numerics/safe_base_operations.hpp.
                "@platforms//os:windows": ["/permissive-"],
                "//conditions:default": [],
            }),
            target_compatible_with = target_compatible_with,
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
