def gen_test_targets(name, cc_srcs):
    """Generates a cc_test target for each source file.

    Args:
      name: name of this macro (unused)
      cc_srcs: test files to generate cc_test targets for
    """

    for src in cc_srcs:
        name = src.removeprefix("test/").removesuffix(".cc") + "_test"
        native.cc_test(
            name = name,
            srcs = [src],
            deps = [
                ":avro_cpp",
                "@boost.test",
            ],
        )
