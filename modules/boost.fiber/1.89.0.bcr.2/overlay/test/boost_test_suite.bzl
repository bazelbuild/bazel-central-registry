"""Test generation for the upstream Boost.Fiber suite."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, srcs):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources, one translation unit per test.
    """
    tests = []
    for src in srcs:
        test_name = src.removeprefix("test_").removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src],
            local_defines = select({
                "@platforms//os:windows": ["_WIN32_WINNT=0x0601"],
                "//conditions:default": [],
            }),
            deps = [
                "@boost.assert",
                "@boost.atomic",
                "@boost.bind",
                "@boost.chrono",
                "@boost.core",
                "@boost.fiber",
                "@boost.function",
                "@boost.test",
                "@boost.test//:unit_test_main",
                "@boost.thread",
            ],
        )
    native.test_suite(name = name, tests = tests)
