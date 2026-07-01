def gen_test_targets(name, cc_srcs, header_srcs):
    """Generates a cc_test target for each source file.

    Args:
      name: name of this macro (unused)
      cc_srcs: test files to generate cc_test targets for
      header_srcs: header files
    """

    for src in cc_srcs:
        name = src.removeprefix("test/").removesuffix(".cpp").replace("/", "_")
        native.cc_test(
            name = name,
            srcs = [src] + header_srcs,
            deps = [":boost.heap_test_lib"],
            local_defines = select({
                "@platforms//os:windows": ["BOOST_ALL_NO_LIB"],
                "//conditions:default": [],
            }),
        )
