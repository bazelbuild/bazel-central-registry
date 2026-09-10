# Folly 2026.08.31.00 Bazel overlay

The BUILD overlay is carried forward from `folly@2026.05.18.00` and reconciled
with the public upstream `v2026.08.31.00` source tree. Targets were updated for
sources that were added, moved, or removed:

* `folly/executors:edf_thread_pool_executor` is header-only now that
  `EDFThreadPoolExecutor.cpp` is gone, and `folly/functional:partial` was
  dropped along with `Partial.h`.
* New upstream files got the targets their `BUCK` files define:
  `folly/random:splitmix64`, `folly/container:generational_cache_map`,
  `folly/debugging/symbolizer:symbol_cache`,
  `folly/io/async:io_uring_buffer_provider` and
  `folly/io/async:io_uring_dynamic_provided_buffer_ring`.
* `double-conversion` is no longer a dependency; folly formats through `fmt`.
  The two patches that rewrote its include style were dropped with it.
* `folly/test` and `folly/io/async/test` are back, trimmed to the test-support
  libraries that `fizz`, `wangle`, `mvfst` and `proxygen` link against
  (`test_utils`, `mocks`, `async_socket_test_lib`, `async_ssl_socket_test_lib`,
  `test_ssl_server`, `mock_server_socket`, `util`) rather than folly's whole
  test suite.

`test_utils_bazel_runfiles.patch` makes `folly::test::find_resource` look the
resource up under `TEST_SRCDIR`, trying each repository directory in the
runfiles tree. The previous version hardcoded the `folly/` prefix and could
only find folly's own data files; dependent modules need to find theirs. The
CMake and internal-extension lookups are unchanged, and the patch no longer
needs `@bazel_tools//tools/cpp/runfiles`.

When updating this module:

1. Reconcile the overlay with the new upstream source layout, using each
   directory's `BUCK` file as the reference for target names and deps.
2. Run Buildifier over all Bazel files in the module version directory.
3. Regenerate `source.json` integrity hashes.
4. Build `@folly//folly/...` to validate the complete overlay.
