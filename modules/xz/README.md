# xz (liblzma)

Starting with 5.8.4, Linux and macOS x86-64 platforms that advertise PCLMUL,
SSSE3, and SSE4.1 through `platforms_contrib` select the direct hardware CRC32
and CRC64 paths. Other x86-64 platforms retain upstream runtime CPU detection
and a software fallback. PCLMUL is not implied by x86-64-v2, v3, or v4.

For example, add `platforms_contrib` to your root `MODULE.bazel`:

```starlark
bazel_dep(name = "xz", version = "5.8.4")
bazel_dep(name = "platforms", version = "1.1.0")
bazel_dep(name = "platforms_contrib", version = "1.0.0-alpha.0")
```

Then describe a target platform whose CPUs support these features:

```starlark
load("@platforms_contrib//cpu/x86_64:x86_64.bzl", "x86_64_level_constraints")

platform(
    name = "linux_x86_64_v3_clmul",
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
        "@platforms_contrib//cpu/x86_64/feature:pclmul_available",
    ] + x86_64_level_constraints("v3"),
)
```

Linux and macOS ARM64 builds enable CRC32 instructions with upstream runtime
feature detection. Baseline ARMv8-A targets keep the software fallback.
