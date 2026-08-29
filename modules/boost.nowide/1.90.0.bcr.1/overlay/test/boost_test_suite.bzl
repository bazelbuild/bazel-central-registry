"""Test generation for the upstream Boost.Nowide suite."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

# Upstream puts the test directory itself on the include path.
_COPTS = select({
    "@platforms//os:windows": ["/I."],
    "//conditions:default": ["-I."],
})

def boost_test_helpers():
    """The helper library upstream links into the file based tests."""
    cc_library(
        name = "file_test_helpers",
        testonly = True,
        srcs = ["file_test_helpers.cpp"],
        hdrs = native.glob(["*.hpp"]),
        copts = _COPTS,
        deps = ["@boost.nowide"],
    )

def boost_test_suite(name, tests):
    """Generates a cc_test target per upstream test.

    Args:
        name: name of the generated test_suite.
        tests: test name -> {src, defines, deps, linkopts, target_compatible_with}.
    """
    for test_name, spec in tests.items():
        cc_test(
            name = test_name,
            srcs = [spec["src"]] + native.glob(["*.hpp"]),
            copts = _COPTS,
            linkopts = spec.get("linkopts", []),
            local_defines = spec.get("defines", []),
            target_compatible_with = spec.get("target_compatible_with", []),
            deps = spec.get("deps", []) + ["@boost.nowide"],
        )
    native.test_suite(name = name, tests = tests.keys())
