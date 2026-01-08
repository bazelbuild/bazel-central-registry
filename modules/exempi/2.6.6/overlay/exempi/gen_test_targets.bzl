load("@rules_cc//cc:defs.bzl", "cc_test")

def gen_test_targets(name, cc_srcs):
    """Generates a cc_test target for each source file.

    Args:
      name: name of this macro (unused)
      cc_srcs: test files to generate cc_test targets for
    """

    for src in cc_srcs:
        name = src.removeprefix("tests/test-").removeprefix("tests/test").removesuffix(".cpp").replace("/", "_").replace("-", "_") + "_test"
        cc_test(
            name = name,
            srcs = [src],
            deps = [":exempi_test_lib"],
            data = [":test_dir"],
            env = {
                "TEST_DIR": "$(rootpath :test_dir)",
                "srcdir": "$(rootpath :test_dir)/../",
            },
        )
