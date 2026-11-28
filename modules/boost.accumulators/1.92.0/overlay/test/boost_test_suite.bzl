"""Test generation for the upstream Boost.Accumulators suite."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, srcs, target_compatible_with = []):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources, one translation unit per test.
        target_compatible_with: platform constraints for these tests.
    """
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src],
            target_compatible_with = target_compatible_with,
            deps = [
                "@boost.accumulators",
                "@boost.foreach",
                "@boost.mpl",
                "@boost.random",
                "@boost.range",
                "@boost.serialization",
                "@boost.test",
                "@boost.test//:unit_test_main",
                "@boost.type_traits",
                "@boost.utility",
            ],
        )
    native.test_suite(name = name, tests = tests)
