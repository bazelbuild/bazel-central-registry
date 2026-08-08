# RocksDB 11.1.2

## Test Exclusions

**Tool tests** (`tools/**_test.cc`): In 11.1.2, tool code began depending on `db_stress_tool/` infrastructure which is not included in the BCR build.

**Additional exclusions beyond 9.11.2:**

- `util/compression_test.cc` - Parameterized test only instantiates when ZSTD is enabled. The `rocksdb` library uses `local_defines` so feature flags don't propagate to test targets, causing the test to fail even when `--@rocksdb//:with_zstd` is passed.

- `table/sst_file_reader_test.cc` - Incompatible with `flush_verify_memtable_count` verification added in 11.1.2.

- `utilities/transactions/lock/point/point_lock_manager_test.cc` - Times out after 900s (stress test variant passes in 210s).
