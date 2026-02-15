"""boost_test_suite"""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, cc_srcs, deps = [], defines = []):
    """Generates a cc_test target for each source file.

    Each of boost.sort's tests have their own main function, so each test needs
    to be a separate cc_test target.

    Args:
        name: name of this macro
        cc_srcs: test files to generate cc_test targets for
        deps: Dependencies for all tests.
        defines: Defines to add to all tests.
    """

    tests = []
    for src in cc_srcs:
        test_name = src.removeprefix("test/").removeprefix("test_").removesuffix(".cpp").removesuffix("_test").replace("/", "_") + "_test"
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src],
            deps = deps,
            defines = defines,
            linkopts = select({
                "@platforms//os:linux": ["-lpthread"],
                "//conditions:default": [],
            }),
        )

    native.test_suite(
        name = name,
        tests = tests,
    )
