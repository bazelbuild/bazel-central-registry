"""Test generation for the upstream Boost.Cobalt suite."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

_COPTS = select({
    "@platforms//os:windows": [
        "/std:c++20",
        "/bigobj",
    ],
    "//conditions:default": ["-std=c++20"],
})

_LOCAL_DEFINES = ["BOOST_ASIO_NO_DEPRECATED"] + select({
    "@platforms//os:windows": [
        "WIN32_LEAN_AND_MEAN",
        "_SCL_SECURE_NO_WARNINGS",
        "_CRT_SECURE_NO_DEPRECATE",
    ],
    "//conditions:default": [],
})

def boost_test_impl():
    """The Boost.Test main upstream links into every test."""
    cc_library(
        name = "test_impl",
        testonly = True,
        srcs = ["test_main.cpp"],
        # It only provides init_unit_test_suite, which the linker looks for
        # after it has already scanned this archive.
        alwayslink = True,
        copts = _COPTS,
        linkstatic = True,
        local_defines = _LOCAL_DEFINES,
        deps = [
            "@boost.cobalt",
            "@boost.test",
        ],
    )

def boost_test_suite(name, srcs, extra_srcs = [], deps = []):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources, one translation unit per test.
        extra_srcs: sources compiled into every test of this suite.
        deps: additional dependencies for these tests.
    """
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp").replace("/", "_")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + extra_srcs + native.glob(["**/*.hpp"]),
            copts = _COPTS,
            # With Boost.Test linked dynamically its globals end up both in the
            # shared library and in the test binary, and are destroyed twice.
            linkstatic = True,
            local_defines = _LOCAL_DEFINES,
            deps = deps + [
                "@boost.cobalt",
                "@boost.test",
            ],
        )
    native.test_suite(name = name, tests = tests)
