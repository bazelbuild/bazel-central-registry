"""Test generation for the upstream Boost.Contract suite."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

_DEPS = [
    "@boost.bind",
    "@boost.config",
    "@boost.contract",
    "@boost.core",
    "@boost.detail",
    "@boost.iostreams",
    "@boost.lexical_cast",
    "@boost.optional",
    "@boost.preprocessor",
    "@boost.static_assert",
    "@boost.type_traits",
]

def boost_test_suite(name, srcs, extra_srcs = {}, local_defines = {}):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources, given as `<subdir>/<name>.cpp`.
        extra_srcs: additional sources keyed by test source.
        local_defines: additional defines keyed by test source.
    """
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp").replace("/", "_")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + extra_srcs.get(src, []) + native.glob(["**/*.hpp"]),
            local_defines = local_defines.get(src, []),
            deps = _DEPS,
        )
    native.test_suite(name = name, tests = tests)
