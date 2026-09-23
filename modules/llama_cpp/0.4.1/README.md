# llama.cpp (Bazel Central Registry overlay)

Upstream [llama.cpp](https://github.com/ggml-org/llama.cpp) builds with CMake and
ships no Bazel files, so this module adds them through `overlay/`:

- `overlay/MODULE.bazel` — Bzlmod module definition.
- `overlay/BUILD.bazel` — `ggml` (base + CPU backend + optional CUDA backend) and
  `llama` (libllama).
- `overlay/test_module/` — the `bcr_test_module` used by presubmit.

The portable CPU backend is always built and works out of the box on Linux,
macOS (x86_64 and arm64) and Windows (MSVC). The remaining GPU backends
(Vulkan, Metal, HIP, SYCL) are intentionally not part of this module; they can
be layered on top of `@llama_cpp//:ggml_base` by the consumer.

`GGML_VERSION`, `GGML_COMMIT` and `LLAMA_VERSION` are normally injected by
upstream CMake. They are hard-coded in `overlay/BUILD.bazel` to the values of the
`v0.4.1` tag.

## Usage

```starlark
# MODULE.bazel
bazel_dep(name = "llama_cpp", version = "0.4.1")
```

```starlark
# BUILD.bazel
cc_binary(
    name = "my_app",
    srcs = ["my_app.cc"],
    deps = ["@llama_cpp//:llama"],
)
```

## CUDA

ggml's CUDA backend is off by default so that CPU-only consumers do not need a
CUDA toolkit. Turn it on with a single flag:

```
build --@llama_cpp//:cuda=true
```

This adds `@llama_cpp//:ggml_cuda` to `:ggml`, defines `GGML_USE_CUDA` in the
backend registry and makes `ggml_backend_cuda_reg()` available at runtime, so
`@llama_cpp//:llama` offloads to the GPU without any further changes.

The toolkit comes from `@rules_cuda`. By default it is detected from the local
installation (`CUDA_PATH`); a hermetic toolkit can be configured in the root
module:

```starlark
cuda = use_extension("@rules_cuda//cuda:extensions.bzl", "toolchain")
cuda.redist_json(
    name = "cuda_redist",
    platforms = ["linux-x86_64", "windows-x86_64"],
    version = "13.0.0",
)
cuda.toolkit(name = "cuda")
use_repo(cuda, "cuda")
```

`:ggml_cuda` carries `target_compatible_with = requires_cuda()`, so it is
automatically skipped when no valid CUDA toolchain is configured. The BCR
presubmit images have no CUDA toolkit, so CI only covers the CPU targets.

Under `bazel test` the CUDA runtime libraries are not on the test environment's
search path, so a CUDA-enabled test needs `--test_env=PATH` (Windows) or
`--test_env=LD_LIBRARY_PATH` (Linux).
