# AWS SDK for C++

The BUILD overlays translate the SDK and bundled CRT libraries' CMake targets.
The module extension selectively extracts the SDK sources needed by those targets.

## Hardware checksums

Starting with `1.11.876.bcr.4`, `aws-checksums` uses the target platform's
[`platforms_contrib`](https://github.com/bazel-contrib/platforms_contrib)
x86-64 constraints to select hardware implementations:

| Target features | CRC32C | CRC64NVME |
| --- | --- | --- |
| Generic x86-64, or no PCLMUL | Software | Software |
| v2 and PCLMUL | SSE4.2 | Software |
| v3 and PCLMUL | SSE4.2 | CLMUL |
| v4, PCLMUL, and VPCLMULQDQ | AVX-512 | AVX-512 |

PCLMUL is not implied by the microarchitecture levels. VPCLMULQDQ is not implied
by v4; v4 platforms without it use the v3 implementations.

For example, a Linux x86-64-v3 platform with PCLMUL can be defined with:

```starlark
load("@platforms_contrib//cpu/x86_64:x86_64.bzl", "x86_64_level_constraints")

platform(
    name = "linux_x86_64_v3",
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
        "@platforms_contrib//cpu/x86_64/feature:pclmul_available",
    ] + x86_64_level_constraints("v3"),
)
```

Add `bazel_dep(name = "platforms_contrib", version = "1.0.0-alpha.0")` to your
root module and select this platform with `--platforms=//:linux_x86_64_v3`.
For a local build, `--platforms=@platforms_contrib//host:native` selects the
automatically detected host features.

On Linux AArch64, CRC and PMULL implementations are built separately from the
dispatcher with their required ISA flags. `platforms_contrib` does not yet
provide ARM feature constraints. AWS checks CPU capabilities at runtime and
falls back to software when an implementation's required features are absent.
