load("@rules_cc//cc:defs.bzl", "cc_test")

def gen_test_targets(name, srcs):
    """Generates a cc_test target for each source file.

    Args:
      name: name of this macro (unused)
      srcs: test files to generate cc_test targets for
    """

    for src in srcs:
        name = src.removesuffix(".cc").replace("/", "_")
        cc_test(
            name = name,
            srcs = [src],
            deps = [":rocksdb_test_lib"],
            linkopts = ["-ldl"],  # for Debian
            timeout = "long",
        )
