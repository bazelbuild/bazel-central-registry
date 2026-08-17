"""Test generation for the upstream Boost.Hana suite."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

_DEPS = [
    ":test_support",
    "@boost.core",
    "@boost.fusion",
    "@boost.hana",
    "@boost.mpl",
    "@boost.tuple",
]

def boost_test_support():
    """Exposes the shared test helpers the upstream tests include."""

    # Upstream puts `_include` on the include path, so <laws/...>,
    # <support/...> and <auto/...> resolve from there.
    cc_library(
        name = "test_support",
        testonly = True,
        hdrs = native.glob(["_include/**/*.hpp"]),
        strip_include_prefix = "_include",
        deps = [
            "@boost.hana",
        ],
    )

def boost_test_suite(name, srcs, hdrs):
    """Generates a cc_test target per upstream test translation unit.

    Args:
        name: name of the generated test_suite.
        srcs: test sources, one translation unit per test.
        hdrs: headers the tests include from their own directory.
    """
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp").replace("/", "_")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + hdrs,
            deps = _DEPS,
        )
    native.test_suite(name = name, tests = tests)
