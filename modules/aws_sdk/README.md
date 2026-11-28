# AWS SDK for C++

The BUILD overlays translate the SDK and bundled CRT libraries' CMake targets.
The module extension selectively extracts the SDK sources needed by those targets.

## Components

Starting with `1.11.876.bcr.6`, every library in the SDK release archive is a
target:

- Each of the 433 generated service clients, named after its directory under
  `generated/src/aws-cpp-sdk-*` with dashes replaced by underscores, for
  example `@aws_sdk//:s3`, `@aws_sdk//:s3_crt` and `@aws_sdk//:bedrock_runtime`.
  Each service is extracted into its own repository, so a build only fetches
  the services it uses. Each repository fetch decompresses the 88 MB SDK
  archive, which takes about 2.4 s of CPU, and copies the archive out of the
  repository cache first. Fetching every service, as `bazel build
  @aws_sdk//...`, `bazel fetch --all` or `bazel vendor` does, therefore takes
  about 1,000 CPU-seconds and writes about 38 GB of temporary copies; pass
  `--experimental_repository_cache_hardlinks` to avoid the copies.
- The hand-written libraries: `@aws_sdk//:access_management`,
  `:identity_management`, `:queues`, `:s3_encryption`, `:s3_transfer`,
  `:text_to_speech` and `:transfer`.
- `@aws_sdk//:core` and the CRT libraries (`:crt`, `:aws-c-common`, ...).

`text_to_speech` is built without PulseAudio, which BCR does not provide, so
it has no built-in audio driver; supply a `PCMOutputDriverFactory`.

## Build settings

These settings mirror the SDK's CMake options. Set them on the command line or
in `.bazelrc`, for example `--@aws_sdk//:http_client=crt`.

| Setting | Values | Default | CMake option |
| --- | --- | --- | --- |
| `@aws_sdk//:http_client` | `curl`, `crt`, `none` | `curl` | `USE_CRT_HTTP_CLIENT`, `NO_HTTP_CLIENT` |
| `@aws_sdk//:min_tls_version` | `1.0`, `1.2`, `1.3` | `1.2` | `USE_TLS_V1_2`, `USE_TLS_V1_3` |
| `@aws_sdk//:request_compression` | `true`, `false` | `true` | `ENABLE_ZLIB_REQUEST_COMPRESSION` |
| `@aws_sdk//:curl_logging` | `true`, `false` | `true` | `ENABLE_CURL_LOGGING` |
| `@aws_sdk//:disable_imdsv1` | `true`, `false` | `false` | `DISABLE_INTERNAL_IMDSV1_CALLS` |
| `@aws_sdk//:memory_management` | `true`, `false` | `false` | `CUSTOM_MEMORY_MANAGEMENT` |
| `@aws_sdk//:opentelemetry` | `true`, `false` | `true` | `BUILD_OPTEL` |
| `@aws_sdk//:user_agent_customization` | any string | empty | `AWS_USER_AGENT_CUSTOMIZATION` |

- `min_tls_version` applies to the curl client. Earlier BCR versions did not
  enforce a minimum, which matches `1.0`.
- With `http_client=none`, the application must set
  `SDKOptions::httpOptions.httpClientFactory_create_fn` before creating
  clients; otherwise client creation fails.
- `opentelemetry` defaults to `true`, unlike CMake, to match earlier BCR
  versions.
- The TLS library is selected by `@curl//:ssl_lib`, as described in
  `BUILD.bazel`.

The SDK C++ libraries set `linkstatic = True`. `@curl//:curl` hides its symbols
and has no shared library, so a dynamically linked core, as in `cc_test`'s
default dynamic mode, fails at startup with undefined curl symbols.

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

ARMv7 retains its existing source selection and software checksum implementations.
Hardware checksum acceleration is enabled only for x86-64 and AArch64 targets.
