# hegel-cpp overlay

Hegel for C++ lives in the hegeldev/hegel monorepo, in `frontends/cpp`,
and its releases include only a CMake build. The module is the monorepo
archive at the frontend's release tag (`frontends/cpp/<version>`), with a
Bazel build added as a registry overlay: `MODULE.bazel`, `BUILD.bazel`,
and `libhegel/{BUILD.bazel,libhegel.bzl}`.

The build mirrors the CMake `hegel` library target in `frontends/cpp`:

- `//:hegel` (also reachable as `@hegel-cpp`, the alias `//:hegel-cpp`)
  compiles `frontends/cpp/src/*.cpp` with reflection enabled
  (`HEGEL_HAS_REFLECTION=1`) and requires C++20.
- reflect-cpp comes from the registry at the version
  `frontends/cpp/CMakeLists.txt` fetches (0.22.0). hegel uses only
  reflection (`rfl::to_view`), so it depends on `@reflect-cpp//:core`
  rather than a serialization format.
- libhegel, the native engine, is the prebuilt shared library from the
  monorepo's GitHub release `libhegel/0.51.1`: the version of the in-tree
  engine (`libhegel/Cargo.toml`) that the CMake build compiles with
  cargo. `//libhegel` pairs it with the in-tree C ABI header
  `libhegel/include/hegel.h`, which is the header that release publishes,
  and pins the SHA-256 hashes from the release's `.sha256` sidecars. The
  CMake build supports Linux and macOS hosts, so the overlay models the
  prebuilt engines for linux-amd64, linux-arm64, and darwin-arm64 (none
  is published for darwin-amd64).
- `--@hegel-cpp//:throw_site=false` is the equivalent of the CMake
  option `HEGEL_THROW_SITE=OFF`, for toolchains that link the C++
  runtime statically.

The test suite is not part of the overlay.
