"""Test generation for the upstream Boost.Redis suite."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

# Upstream also configures Boost.Asio here, but those defines change the layout
# of Asio types and @boost.asio is not built with them.
_LOCAL_DEFINES = [
    # Deprecated functions are part of what the tests cover.
    "BOOST_ALLOW_DEPRECATED=1",
] + select({
    "@platforms//os:windows": ["_WIN32_WINNT=0x0601"],
    "//conditions:default": [],
})

_COPTS = select({
    "@platforms//os:windows": ["/bigobj"],
    "//conditions:default": [],
})

_DEPS = [
    "@boost.asio",
    "@boost.assert",
    "@boost.core",
    "@boost.redis",
    "@boost.system",
    "@boost.test",
]

def boost_test_common():
    """The helper library upstream links into every test."""
    cc_library(
        name = "redis_test_common",
        testonly = True,
        srcs = [
            "boost_redis.cpp",
            "common.cpp",
        ],
        hdrs = native.glob(["*.hpp"]),
        copts = _COPTS,
        # Upstream links this statically; as a shared library the Boost.Test
        # globals end up duplicated between it and the test binary.
        linkstatic = True,
        local_defines = _LOCAL_DEFINES,
        deps = _DEPS,
    )

def boost_test_suite(name, srcs, unit_test_main = False):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources, one translation unit per test.
        unit_test_main: whether the tests get their main from Boost.Test.
    """
    tests = []
    for src in srcs:
        test_name = src.removeprefix("test_").removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src],
            copts = _COPTS,
            # With Boost.Test linked dynamically its globals end up both in the
            # shared library and in the test binary, and are destroyed twice.
            linkstatic = True,
            local_defines = _LOCAL_DEFINES,
            deps = _DEPS + [":redis_test_common"] +
                   (["@boost.test//:unit_test_main"] if unit_test_main else []),
        )
    native.test_suite(name = name, tests = tests)
