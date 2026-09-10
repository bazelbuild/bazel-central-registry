# Proxygen 2026.08.31.00 Bazel overlay

Carried forward from `proxygen@2025.02.10.00.bcr.1` and reconciled with
upstream `v2026.08.31.00`. The bulk of the change is the `proxygen/lib/http/coro`
subtree, which did not exist in the previous version.

* `proxygen/lib/dns` is now built. It needs only c-ares, which was already a
  declared dependency, and `proxygen/lib/http/coro/client` does not compile
  without it. Only `AsyncDNSStatsCollector`, which reaches into the excluded
  `proxygen/lib/stats`, stays out.
* The library gained the `@folly//folly/coro` and `@folly//folly/io/coro`
  targets the coro sources include, plus `folly:move_wrapper`,
  `folly/fibers:batch_semaphore` and `folly/io/async:async_signal_handler`.
* `folly/experimental/io` and `folly/experimental/symbolizer` moved to
  `folly/io/async` and `folly/debugging/symbolizer`.
* Excluded from the library: coro sample binaries and benchmarks,
  `StatsFilterUtil` (needs the excluded stats library), and
  `proxygen/lib/http/coro/transport/test/Client.cpp`, a sample client whose
  `main` was being linked into every test binary.
* `httpclient_samples_pricli` is gone; upstream removed the sample.
* `httpserver_test_lib` now compiles `HTTPServerTestUtils.cpp`, which the coro
  server test links against.
* `SKIPPED_TEST_CASES` lists the individual test cases that do not pass here,
  each with the reason. They are excluded through `--gtest_filter` so the rest
  of each binary still runs.
* Two files in the new coro subtree are left out of the build because of GCC
  coroutine bugs, each with the details in a comment on its exclusion:
  `.../transport/test/HTTPConnectTransportTest.cpp` crashes GCC 13 with an
  internal compiler error in `build_special_member_call`, and
  `.../test/HTTPTransactionAdaptorSourceTest.cpp` corrupts the heap under
  GCC 11 (`munmap_chunk(): invalid pointer`) from a mismanaged coroutine
  frame. Both run cleanly on GCC 15, and the second reproduces identically on
  x86-64 and aarch64.

Patches:

* `test_main_folly_init.patch` — the shared gtest `main` now runs `folly::Init`,
  which marks the singleton vault registration complete. Without it every test
  touching `folly::Timekeeper` (most of the coro suite) aborts.
* `bazel_runfiles_paths_for_tests.patch` — resolves test data through Bazel
  runfiles rather than `XLOG_FILENAME`/`__FILE__`, including the coro client's
  TLS certificates, which go through `folly::test::find_resource`.
* `drop_internal_only_mock_filter.patch` — removes a mock that includes a
  header from Meta's internal tree, absent from the open-source release.
* `fix_worker_thread_gflags.patch`, `push_sample_use_bazel_runfiles.patch` —
  carried forward unchanged in intent from the previous version.
