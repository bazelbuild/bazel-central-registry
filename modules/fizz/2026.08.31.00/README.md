# Fizz 2026.08.31.00 Bazel overlay

Carried forward from `fizz@2025.02.10.00.bcr.2` and reconciled with upstream
`v2026.08.31.00`.

* `fizz/fizz-config.h` gained two new template substitutions:
  `FIZZ_HAVE_SODIUM` is enabled (libsodium is already a dependency) and
  `FIZZ_LOGGING_BACKEND` is set to `GLOG`, matching the CMake default.
* `*Bench.cpp` files are excluded from the library glob; they are benchmarks,
  not library sources, and pull in `folly/Benchmark.h`.
* The `tool` binary gained `@folly//folly/init`, which its `main` now uses.
