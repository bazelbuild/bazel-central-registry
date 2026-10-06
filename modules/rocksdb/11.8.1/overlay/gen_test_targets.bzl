load("@rules_cc//cc:cc_test.bzl", "cc_test")

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
            copts = ["-std=c++20"],
            deps = [":rocksdb_test_lib"],
            linkopts = select({
                "@platforms//os:linux": ["-ldl"],
                "@platforms//os:macos": [],
            }),
            timeout = "long",
        )
