def gen_test_targets(name, cc_srcs):
    """Generates a cc_test target for each source file.

    Each of boost.sort's tests have their own main function, so each test needs
    to be a separate cc_test target.

    Args:
      name: name of this macro (unused)
      cc_srcs: test files to generate cc_test targets for
    """

    for src in cc_srcs:
        name = src.removeprefix("test/").removeprefix("test_").removesuffix(".cpp").removesuffix("_test").replace("/", "_") + "_test"
        native.cc_test(
            name = name,
            srcs = [src],
            deps = [
                ":boost.sort",
                "@boost.test",
            ],
            linkopts = select({
                "@platforms//os:linux": ["-lpthread"],
                "//conditions:default": [],
            }),
        )
