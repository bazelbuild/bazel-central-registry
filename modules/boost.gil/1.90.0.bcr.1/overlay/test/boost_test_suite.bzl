"""Test generation for the upstream Boost.GIL suite."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

# Upstream puts the test directory itself on the include path.
_COPTS = select({
    "@platforms//os:windows": [
        "/I.",
        "/bigobj",
    ],
    "//conditions:default": ["-I."],
})

_DEPS = [
    "@boost.array",
    "@boost.assert",
    "@boost.concept_check",
    "@boost.config",
    "@boost.container_hash",
    "@boost.core",
    "@boost.gil",
    "@boost.mp11",
    "@boost.preprocessor",
]

def boost_test_suite(name, srcs, local_defines = []):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources, one translation unit per test.
        local_defines: defines upstream sets for this suite.
    """
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp").replace("/", "_")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + native.glob(["**/*.hpp"]),
            copts = _COPTS,
            local_defines = local_defines,
            deps = _DEPS,
        )
    native.test_suite(name = name, tests = tests)
