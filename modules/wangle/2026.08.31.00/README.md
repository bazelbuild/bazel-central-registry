# Wangle 2026.08.31.00 Bazel overlay

Carried forward from `wangle@2025.02.10.00.bcr.2` and reconciled with upstream
`v2026.08.31.00`.

* Upstream added `wangle/wangle-config.h`, generated here with
  `expand_template` and pinned to the `GLOG` logging backend, matching the
  CMake default. It is consumed by `wangle/util/Logging.h`, so it belongs to
  the `util` target.
* `folly/experimental/io` moved to `folly/io/async`, so `:acceptor` now depends
  on `@folly//folly/io/async:async_io_uring_socket`.
* `:ssl` needs `@fizz` directly for `fizz/record/Types.h` and the OpenSSL
  certificate types; `:client_persistence` needs `:util` for the new
  `wangle/util/Logging.h`.
