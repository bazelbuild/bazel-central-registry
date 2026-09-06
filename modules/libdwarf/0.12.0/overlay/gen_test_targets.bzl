def gen_test_targets(name, cc_srcs):
    """Generates a cc_test target for each source file.

    Args:
      name: name of this macro (unused)
      cc_srcs: test files to generate cc_test targets for
    """

    for src in cc_srcs:
        name = src.removeprefix("test/test_").removesuffix(".c").replace("/", "_") + "_test"
        native.cc_test(
            name = name,
            srcs = [src],
            deps = [
                ":dwarf",
                ":dwarfdump",
            ],
            local_defines = ["TESTING"],
        )
