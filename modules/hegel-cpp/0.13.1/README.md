# hegel-cpp overlay

hegel-cpp's release archives include only a CMake build, so this module
adds a Bazel build as a registry overlay: `MODULE.bazel`, `BUILD.bazel`,
and `libhegel/{BUILD.bazel,libhegel.bzl}`.

The build mirrors the CMake `hegel` library target:

- `//:hegel` compiles `src/*.cpp` with reflection enabled
  (`HEGEL_HAS_REFLECTION=1`) and requires C++20.
- reflect-cpp comes from the registry at the version `CMakeLists.txt`
  fetches (0.22.0). hegel uses only reflection (`rfl::to_view`), so it
  depends on `@reflect-cpp//:core` rather than a serialization format.
- libhegel, the native engine, is the prebuilt shared library from the
  hegel-rust GitHub release `libhegel-v0.42.4`: the version in
  `cmake/libhegel.cmake`, with the SHA-256 pins from `nix/flake.nix`.
  Like the Nix build, the overlay supports linux-amd64, linux-arm64, and
  darwin-arm64.
- `--@hegel-cpp//:throw_site=false` is the equivalent of the CMake
  option `HEGEL_THROW_SITE=OFF`, for toolchains that link the C++
  runtime statically.

The test suite is not part of the overlay.
