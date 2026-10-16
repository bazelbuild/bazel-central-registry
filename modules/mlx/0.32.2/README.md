# MLX 0.32.2 Bazel overlay

## Upstream build sources

The overlay translates the [upstream v0.32.2 CMake build](https://github.com/ml-explore/mlx/tree/v0.32.2).
Paths in the table below are relative to the upstream source archive.

| Overlay definition | Upstream CMake files |
| --- | --- |
| Version, dependencies, backend options, and C++ standard | `CMakeLists.txt` |
| `_CORE_SRCS` | `mlx/CMakeLists.txt`, `mlx/backend/{common,cpu}/CMakeLists.txt`, and `mlx/{distributed,io}/CMakeLists.txt` with their subdirectories |
| `_METAL_SRCS` | `mlx/backend/{metal,gpu}/CMakeLists.txt` |
| `_METAL_JIT_SOURCES` | `make_jit_source` calls in `mlx/backend/metal/CMakeLists.txt` |
| `_METAL_KERNELS` and Metal compiler flags | `mlx/backend/metal/kernels/CMakeLists.txt` |
| `_NO_METAL_SRCS` | `mlx/CMakeLists.txt` and `mlx/backend/no_gpu/CMakeLists.txt` |
| Upstream tests in `overlay/test/BUILD.bazel` | `tests/CMakeLists.txt` |

## Build configuration

The overlay enables the CPU backend on macOS and Linux and the Metal backend on
macOS arm64. It uses `MLX_METAL_JIT=ON`, `MLX_BUILD_CUDA=OFF`, and defines
`MLX_METAL_NO_NAX`. macOS uses Accelerate; Linux uses BCR OpenBLAS.

Metal compilation, linking, and JIT source generation use Bazel's selected
Xcode configuration through `apple_support.run`.

MPI is loaded at runtime. NCCL and JACCL use the upstream `no_*` implementations.
The small ahead-of-time metallib is embedded in the library so consumers need
no separately installed file.

## Patches

| Patch | Purpose |
| --- | --- |
| `use_bcr_nlohmann_json.patch` | Use BCR's `<nlohmann/json.hpp>` include layout. |
| `use_bcr_openblas_lapack.patch` | Avoid the BCR OpenBLAS wrapper's include-guard clash. |
| `embed_metallib.patch` | Load the linked-in metallib in `mlx/backend/metal/device.cpp`. |

## Updating MLX

1. Download and unpack the archive referenced by the new `source.json`, then
   compare the CMake files above with v0.32.2. Update the explicit source lists,
   `make_jit_source` entries, kernel lists, version, dependencies, and test list
   for the same build options.
2. Keep Metal flags and generated-source arguments in `overlay/bazel/*.bzl` in
   sync with those CMake files and the upstream
   `mlx/backend/{cpu,metal}/make_compiled_preamble.sh` scripts.
3. Reapply each patch to the clean archive, checking whether it is still needed.
   Regenerate changed patches with `git diff`, using paths compatible with
   `patch_strip = 1`.
4. Refresh the overlay and patch hashes from the BCR repository root:

   ```sh
   bazel run //tools:update_integrity -- mlx --version <new-version>
   ```

5. Reproduce the build and upstream tests:

   ```sh
   bazel run //tools:setup_presubmit_repos -- --module mlx@<new-version>
   ```

   Also run the corresponding MLX-C test module, covering the platforms and
   Bazel versions in each module's `presubmit.yml`.
