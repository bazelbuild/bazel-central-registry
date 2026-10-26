"""Test generation for the upstream Boost.STLInterfaces suite."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, srcs):
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + native.glob(["*.hpp"]),
            defines = ["BOOST_NO_AUTO_PTR"],
            deps = [
                "@boost.core",
                "@boost.stl_interfaces",
            ],
        )
    native.test_suite(name = name, tests = tests)
