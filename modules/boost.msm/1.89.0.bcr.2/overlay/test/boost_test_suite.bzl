"""Test generation for the upstream Boost.MSM suite."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_headers():
    """Exposes the test headers, which upstream includes with angle brackets."""
    cc_library(
        name = "test_headers",
        testonly = True,
        hdrs = native.glob(["*.hpp"]),
    )

def boost_test_suite(name, srcs, cxxstd = None, local_defines = {}):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources, one translation unit per test.
        cxxstd: C++ standard upstream requires for these tests.
        local_defines: additional defines keyed by test source.
    """
    # Upstream puts the test directory itself on the include path, since the
    # tests include their shared headers with angle brackets.
    copts = select({
        "@platforms//os:windows": ["/I."],
        "//conditions:default": ["-I."],
    })
    if cxxstd:
        copts = copts + select({
            "@platforms//os:windows": ["/std:c++" + cxxstd],
            "//conditions:default": ["-std=c++" + cxxstd],
        })

    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src],
            copts = copts,
            local_defines = local_defines.get(src, []),
            deps = [
                ":test_headers",
                "@boost.core",
                "@boost.fusion",
                "@boost.msm",
                "@boost.parameter",
                "@boost.serialization",
                "@boost.test",
                "@boost.test//:unit_test_main",
            ],
        )
    native.test_suite(name = name, tests = tests)
