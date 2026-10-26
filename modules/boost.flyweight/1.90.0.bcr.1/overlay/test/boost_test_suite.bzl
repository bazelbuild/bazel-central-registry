"""Test generation for the upstream Boost.Flyweight suite."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, tests, extra_deps = {}, local_defines = {}):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        tests: test name -> the sources upstream compiles into that binary.
        extra_deps: additional dependencies keyed by test name.
        local_defines: additional defines keyed by test name.
    """
    for test_name, srcs in tests.items():
        cc_test(
            name = test_name,
            srcs = srcs + native.glob(["*.hpp"]),
            local_defines = local_defines.get(test_name, []),
            deps = extra_deps.get(test_name, []) + [
                "@boost.config",
                "@boost.container_hash",
                "@boost.core",
                "@boost.flyweight",
                "@boost.mpl",
                "@boost.serialization",
                "@boost.tuple",
                "@boost.utility",
            ],
        )
    native.test_suite(name = name, tests = tests.keys())
