def gen_test_targets(name, srcs):
    """Generates a cc_test target for each source file.

    rocksdb has a lot of tests that each define their own main function, so we
    need one cc_test per file.

    Args:
      name: name of this macro (unused)
      srcs: test files to generate cc_test targets for
    """

    for src in srcs:
        name = src.removesuffix(".cc").replace("/", "_")
        native.cc_test(
            name = name,
            srcs = [src],
            deps = [":rocksdb_test_lib"],
            linkopts = ["-ldl"],  # for Debian
            timeout = "long",
        )
