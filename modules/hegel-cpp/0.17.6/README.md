# hegel-cpp overlay

Hegel for C++ lives in the hegeldev/hegel monorepo, in `frontends/cpp`,
and its releases include only a CMake build. The module is the source
tarball attached to the frontend's release (tag `frontends/cpp/<version>`),
which holds the frontend and the libhegel engine sources, with a Bazel
build added as a registry overlay: `MODULE.bazel`, `BUILD.bazel`,
`libhegel/BUILD.bazel`, and `cargo-bazel-lock.json`.

The build mirrors the CMake `hegel` library target in `frontends/cpp`:

- `//:hegel` (also reachable as `@hegel-cpp`, the alias `//:hegel-cpp`)
  compiles `frontends/cpp/src/*.cpp` with reflection enabled
  (`HEGEL_HAS_REFLECTION=1`) and requires C++20.
- reflect-cpp comes from the registry at the version
  `frontends/cpp/CMakeLists.txt` fetches (0.22.0). hegel uses only
  reflection (`rfl::to_view`), so it depends on `@reflect-cpp//:core`
  rather than a serialization format.
- libhegel, the native engine, is built from the in-tree Rust crate
  (`libhegel/`, the `hegeltest-c` crate) with rules_rust, the way the
  CMake build builds it with cargo. `//libhegel:hegel_c` is a
  `rust_static_library` whose dependencies crate_universe resolves from
  the release's own `Cargo.lock`; it is compiled at `-Copt-level=3`
  whatever the Bazel compilation mode, as cargo's release profile
  would. `//libhegel` pairs it with the in-tree C ABI header
  `libhegel/include/hegel.h`, generated from the same crate. The CMake
  build supports Linux and macOS hosts, and so does the overlay.
- `cargo-bazel-lock.json` is crate_universe's lockfile, which a module
  that is not the root module must ship. It was generated from a
  workspace holding the release tarball plus these overlay files, with
  `CARGO_BAZEL_REPIN=1 bazel sync --only=hegel_cpp_crates`; regenerate
  it the same way when the release's `Cargo.lock` or the rules_rust
  version changes.
- `--@hegel-cpp//:throw_site=false` is the equivalent of the CMake
  option `HEGEL_THROW_SITE=OFF`, for toolchains that link the C++
  runtime statically.

The test suite is not part of the overlay.
