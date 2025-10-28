"""gen_test_targets"""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

def gen_test_targets(name, cc_srcs, header_srcs):
    """Generates a cc_test target for each source file.

    Args:
      name: name of this macro (unused)
      cc_srcs: test files to generate cc_test targets for
      header_srcs: header files
    """

    for src in cc_srcs:
        name = src.removeprefix("test/").removesuffix(".cpp").replace("/", "_")
        cc_test(
            name = name,
            srcs = [src] + header_srcs,
            deps = [
                "@boost.container",
                "@boost.core",
                "@boost.iterator",
                "@boost.tuple",
            ],
        )
