"""Test generation for the upstream Boost.Statechart suite."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

# Upstream runs the whole suite single-threaded, and every runnable test in the
# four RTTI/transition-context variants declared in test/Jamfile.v2.
_COMMON_DEFINES = ["BOOST_DISABLE_THREADS"]

_VARIANTS = {
    "Normal": [],
    "Native": ["BOOST_STATECHART_USE_NATIVE_RTTI"],
    "Relaxed": ["BOOST_STATECHART_RELAX_TRANSITION_CONTEXT"],
    "Both": [
        "BOOST_STATECHART_USE_NATIVE_RTTI",
        "BOOST_STATECHART_RELAX_TRANSITION_CONTEXT",
    ],
}

_DEPS = [
    ":boost_root_headers",
    "@boost.bind",
    "@boost.config",
    "@boost.core",
    "@boost.mpl",
    "@boost.smart_ptr",
    "@boost.statechart",
    "@boost.static_assert",
    "@boost.test//:test_main",
    "@boost.test//:unit_test_main",
]

def boost_root_headers():
    """Exposes the headers the tests include relative to the Boost root."""
    cc_library(
        name = "boost_root_headers",
        testonly = True,
        hdrs = ["ThrowingBoostAssert.hpp"],
        include_prefix = "libs/statechart/test",
    )

def boost_test_suite(name, srcs, variants = _VARIANTS.keys()):
    """Generates a cc_test target per upstream test and variant.

    Args:
        name: name of the generated test_suite.
        srcs: sources of one test binary, or a single test source.
        variants: the variants to generate.
    """
    tests = []
    for variant in variants:
        test_name = srcs[0].removesuffix(".cpp") + variant
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = srcs + native.glob(["*.hpp"]),
            local_defines = _COMMON_DEFINES + _VARIANTS[variant],
            deps = _DEPS,
        )
    native.test_suite(name = name, tests = tests)
