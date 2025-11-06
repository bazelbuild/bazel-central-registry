"""boost_test_suite"""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def boost_test_suite(name, cc_srcs, header_srcs, deps = []):
    """Generates a cc_test target for each source file.

    Each of boost.foreach's tests have their own main function, so each test
    needs to be a separate cc_test target.

    Args:
        name: name of this macro (unused)
        cc_srcs: test files to generate cc_test targets for
        header_srcs: header files
        deps: Dependencies for all tests.
    """

    tests = []
    for src in cc_srcs:
        test_name = src.removeprefix("test/").removesuffix(".cpp").replace("/", "_") + "_test"
        tests.append(test_name)
        cc_test(
            name = test_name,
            srcs = [src] + header_srcs,
            deps = deps,
        )

    native.test_suite(
        name = name,
        tests = tests,
    )
