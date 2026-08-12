"""Test generation for the runnable upstream Boost.OpenMethod tests."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, srcs, deps):
    tests = []
    for src in srcs:
        test_name = src.removeprefix("test_").removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + native.glob(["*.hpp"]),
            copts = select({
                "@platforms//os:windows": ["/std:c++17"],
                "//conditions:default": ["-std=c++17"],
            }),
            deps = deps,
        )
    native.test_suite(name = name, tests = tests)
