"""Test generation for the upstream Boost.Hana suite."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

_DEPS = [
    ":test_headers",
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

    # Several tests include a `_specs.hpp` sitting next to them, which the
    # compiler resolves relative to the including source file.
    cc_library(
        name = "test_headers",
        testonly = True,
        textual_hdrs = native.glob(
            ["**/*.hpp"],
            exclude = ["_include/**"],
        ),
    )

def boost_test_suite(name, srcs):
    """Generates a cc_test target per upstream test translation unit.

    Args:
        name: name of the generated test_suite.
        srcs: test sources, one translation unit per test.
    """
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp").replace("/", "_")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src],
            deps = _DEPS,
        )
    native.test_suite(name = name, tests = tests)
