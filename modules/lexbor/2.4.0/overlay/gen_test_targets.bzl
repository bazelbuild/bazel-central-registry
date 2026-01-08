def gen_test_targets(name, srcs, data, test_args):
    """Generates a cc_test target for each source file.

    Lexbor has a lot of tests and does not use googletest, so it needs one
    cc_test per file.

    Args:
      name: name of this macro (unused)
      srcs: test files to generate cc_test targets for
      data: data attribute to pass to cc_test
      test_args: dictionary of arguments for tests that need them
    """

    for src in srcs:
        name = src.removeprefix("test/").removesuffix(".cpp").removesuffix(".c").replace("/", "_") + "_test"
        native.cc_test(
            name = name,
            srcs = [src],
            deps = [":lexbor_test_lib"],
            data = data,
            args = ["$(location %s)" % test_args[name]] if name in test_args else [],
        )
