"""Test generation for the upstream Boost.LocalFunction suite."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, srcs):
    """Generates a cc_test target per runnable upstream test.

    The `*_nova.cpp` tests `#include` the sibling `.cpp` file they vary, so all
    test sources are also exposed textually through `:test_sources`.

    Args:
        name: name of the generated test_suite.
        srcs: test sources to turn into cc_test targets.
    """
    cc_library(
        name = "test_sources",
        testonly = True,
        textual_hdrs = native.glob([
            "*.cpp",
            "*.hpp",
        ]),
    )

    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src],
            deps = [
                ":test_sources",
                "@boost.concept_check",
                "@boost.config",
                "@boost.core",
                "@boost.detail",
                "@boost.function",
                "@boost.functional",
                "@boost.local_function",
                "@boost.preprocessor",
                "@boost.type_traits",
                "@boost.typeof",
                "@boost.utility",
            ],
        )
    native.test_suite(name = name, tests = tests)
