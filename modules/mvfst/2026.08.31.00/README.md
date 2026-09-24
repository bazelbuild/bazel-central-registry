# mvfst 2026.08.31.00 Bazel overlay

Carried forward from `mvfst@2025.01.20.00.bcr.1` and reconciled with upstream
`v2026.08.31.00`.

* Upstream added `quic/quic-logging-config.h`, generated here with
  `expand_template` and pinned to the `GLOG` backend, matching the CMake
  default.
* The header glob now also picks up `*.hpp`, for the vendored
  `quic/common/third-party/expected.hpp`.
* Sources excluded because they redefine symbols the default implementations
  already provide: the `*Mobile*` factory variants, and
  `quic/fizz/handshake/FizzPacketNumberCipher.cpp`, which upstream's `BUCK`
  selects *instead of* `FizzOpenSSLPacketNumberCipher.cpp`, never alongside it.
* The libev event base and its executor stay excluded until libev is in the
  BCR; `QuicLibevExecutorImpl` was added to that exclusion.

`tperf_nullability_qualifiers.patch` replaces Clang's bare `_Nonnull`
qualifiers in `quic/tools/tperf/TperfTcp.cpp` with folly's `FOLLY_NONNULL`,
which expands to nothing on GCC. Without it the file does not compile with GCC.
