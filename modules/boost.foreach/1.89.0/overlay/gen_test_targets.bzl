def gen_test_targets(name, cc_srcs, header_srcs):
    """Generates a cc_test target for each source file.

    Each of boost.foreach's tests have their own main function, so each test
    needs to be a separate cc_test target.

    Args:
      name: name of this macro (unused)
      cc_srcs: test files to generate cc_test targets for
      header_srcs: header files
    """

    for src in cc_srcs:
        name = src.removeprefix("test/").removesuffix(".cpp").replace("/", "_") + "_test"
        native.cc_test(
            name = name,
            srcs = [src] + header_srcs,
            deps = [":boost.foreach"],
        )
