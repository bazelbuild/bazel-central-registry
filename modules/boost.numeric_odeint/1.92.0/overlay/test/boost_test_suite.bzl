"""Test generation for the upstream Boost.Odeint suite."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

_DEPS = [
    "@boost.config",
    "@boost.core",
    "@boost.format",
    "@boost.fusion",
    "@boost.iterator",
    "@boost.mpl",
    "@boost.multiprecision",
    "@boost.numeric_odeint",
    "@boost.phoenix",
    "@boost.range",
    "@boost.static_assert",
    "@boost.test",
    "@boost.test//:unit_test_main",
    "@boost.type_traits",
    "@boost.units",
    "@boost.utility",
]

_LOCAL_DEFINES = ["BOOST_ALL_NO_LIB=1"]

def boost_test_suite(name, srcs, local_defines = {}):
    """Generates a cc_test target per runnable upstream test.

    Args:
        name: name of the generated test_suite.
        srcs: test sources that define their cases with Boost.Test.
        local_defines: additional defines keyed by test name.
    """
    tests = []
    for src in srcs:
        test_name = src.removesuffix(".cpp")
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + native.glob(["*.hpp"]),
            local_defines = _LOCAL_DEFINES + local_defines.get(test_name, []),
            deps = _DEPS,
        )
    native.test_suite(name = name, tests = tests)

def boost_compile_test_suite(name, srcs):
    """Generates a cc_library target per compile-only upstream test.

    Args:
        name: name of the generated cc_library bundling the compiled tests.
        srcs: compile-only test sources.
    """
    libs = []
    for src in srcs:
        lib_name = src.removesuffix(".cpp")
        libs.append(lib_name)
        cc_library(
            name = lib_name,
            srcs = [src] + native.glob(["*.hpp"]),
            testonly = True,
            local_defines = _LOCAL_DEFINES,
            deps = _DEPS,
        )
    cc_library(name = name, testonly = True, deps = libs)
