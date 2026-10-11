load("@rules_cc//cc:cc_test.bzl", "cc_test")

# These suites exceed 15 minutes on macOS, even while making steady progress.
_SLOW_TESTS = [
    "db_compaction_compaction_service_test",
    "db_db_iterator_test",
    "db_db_wal_test",
    "table_block_based_block_based_table_reader_test",
    "table_table_test",
    "util_compression_test",
    "utilities_transactions_write_committed_transaction_ts_test",
    "utilities_transactions_write_unprepared_transaction_test",
]

# The database-heavy parameter matrices exceed their timeout on macOS ARM64 CI.
# GoogleTest distributes every case across shards without filtering coverage.
_MACOS_TEST_SHARDS = {
    "db_db_wal_test": 4,
    "table_table_test": 16,
    "util_compression_test": 4,
}

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
            shard_count = select({
                "@platforms//os:macos": _MACOS_TEST_SHARDS.get(name, 0),
                "//conditions:default": 0,
            }),
            deps = [":rocksdb_test_lib"],
            linkopts = select({
                "@platforms//os:linux": ["-ldl"],
                "@platforms//os:macos": [],
            }),
            timeout = "eternal" if name in _SLOW_TESTS else "long",
        )
