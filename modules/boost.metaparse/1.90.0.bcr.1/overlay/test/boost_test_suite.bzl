"""Test generation for the upstream Boost.Metaparse suite."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

_DEPS = [
    "@boost.metaparse",
    "@boost.mpl",
    "@boost.preprocessor",
    "@boost.type_traits",
]

def _test_name(src):
    return src.removesuffix(".cpp").lower()

def boost_test_suite(name, srcs):
    """Generates a cc_test target per runnable upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources that define their cases with Boost.Test.
    """
    tests = []
    for src in srcs:
        test_name = _test_name(src)
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + native.glob(["*.hpp"]),
            local_defines = select({
                "@platforms//os:windows": ["BOOST_ALL_NO_LIB"],
                "//conditions:default": [],
            }),
            deps = _DEPS + ["@boost.test//:unit_test_main"],
        )
    native.test_suite(name = name, tests = tests)

def boost_compile_test_suite(name, srcs):
    """Generates a cc_library target per compile-only upstream test.

    Most Boost.Metaparse tests are pure metaprogramming checks that upstream
    runs as `compile` targets, i.e. they have no `main`. Building them is the
    whole test.

    Args:
        name: name of the generated cc_library bundling the compiled tests.
        srcs: compile-only test sources.
    """
    libs = []
    for src in srcs:
        lib_name = _test_name(src)
        libs.append(lib_name)
        cc_library(
            name = lib_name,
            srcs = [src] + native.glob(["*.hpp"]),
            testonly = True,
            deps = _DEPS,
        )
    cc_library(name = name, testonly = True, deps = libs)
