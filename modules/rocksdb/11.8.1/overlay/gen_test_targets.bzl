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
            # CustomFileChecksum can fail during background compactions under load.
            flaky = name == "db_compaction_compaction_service_test",
            deps = [":rocksdb_test_lib"],
            linkopts = select({
                "@platforms//os:linux": ["-ldl"],
                "@platforms//os:macos": [],
            }),
            # Full codec coverage takes over 12 minutes even on Linux amd64.
            timeout = "eternal" if name == "table_table_test" else "long",
        )
