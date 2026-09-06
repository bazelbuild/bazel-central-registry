def _aws_sdk_repository_impl(ctx):
    # 1. Download aws-sdk-cpp (Main)
    ctx.download_and_extract(
        url = "https://github.com/aws/aws-sdk-cpp/archive/refs/tags/1.11.758.tar.gz",
        sha256 = "3c8e9ce925f4e6a825ff8880aae4ecee5b02054fec7e54be71dd946161b93dd9",
        stripPrefix = "aws-sdk-cpp-1.11.758",
    )

    # 2. Download aws-crt-cpp
    ctx.download_and_extract(
        url = "https://github.com/awslabs/aws-crt-cpp/archive/refs/tags/v0.37.2.tar.gz",
        sha256 = "4cb6f65a1116ccc73ea9f068ce0bee98e906f8e0f96229c91681a85b207ebacc",
        output = "crt/aws-crt-cpp",
        stripPrefix = "aws-crt-cpp-0.37.2",
    )

    # 3. Download submodules into crt/aws-crt-cpp/crt/
    submodules = {
        "aws-c-auth": {
            "tag": "v0.9.5",
            "url": "https://github.com/awslabs/aws-c-auth/archive/refs/tags/v0.9.5.tar.gz",
            "sha256": "39000bff55fe8c82265b9044a966ab37da5c192a775e1b68b6fcba7e7f9882fb",
            "strip_prefix": "aws-c-auth-0.9.5"
        },
        "aws-c-cal": {
            "tag": "v0.9.13",
            "url": "https://github.com/awslabs/aws-c-cal/archive/refs/tags/v0.9.13.tar.gz",
            "sha256": "80b7c6087b0af461b4483e4c9483aea2e0dac5d9fb2289b057159ea6032409e1",
            "strip_prefix": "aws-c-cal-0.9.13"
        },
        "aws-c-common": {
            "tag": "v0.12.6",
            "url": "https://github.com/awslabs/aws-c-common/archive/refs/tags/v0.12.6.tar.gz",
            "sha256": "138822ecdcaff1d702f37d4751f245847d088592724921cc6bf61c232b198d6b",
            "strip_prefix": "aws-c-common-0.12.6"
        },
        "aws-c-compression": {
            "tag": "v0.3.2",
            "url": "https://github.com/awslabs/aws-c-compression/archive/refs/tags/v0.3.2.tar.gz",
            "sha256": "f93f5a5d8b3fee3a6d97b14ba279efacd4d4016ef9cc7dc4be7d43519ecfbe93",
            "strip_prefix": "aws-c-compression-0.3.2"
        },
        "aws-c-event-stream": {
            "tag": "v0.5.9",
            "url": "https://github.com/awslabs/aws-c-event-stream/archive/refs/tags/v0.5.9.tar.gz",
            "sha256": "e9371ffe050c24ca4eda439d58a06285db88b550e9cbec006d6ea21db02d424a",
            "strip_prefix": "aws-c-event-stream-0.5.9"
        },
        "aws-c-http": {
            "tag": "v0.10.9",
            "url": "https://github.com/awslabs/aws-c-http/archive/refs/tags/v0.10.9.tar.gz",
            "sha256": "472653537a6c2e9dbf44a4e14991f65e61e65d43c120efe2c5f06b7f57363a2c",
            "strip_prefix": "aws-c-http-0.10.9"
        },
        "aws-c-io": {
            "tag": "v0.26.0",
            "url": "https://github.com/awslabs/aws-c-io/archive/refs/tags/v0.26.0.tar.gz",
            "sha256": "27591a4d67b7401dc0b87f8fec91b1c93764decb32229086113c80d4d6d6d3c0",
            "strip_prefix": "aws-c-io-0.26.0"
        },
        "aws-c-mqtt": {
            "tag": "v0.13.3",
            "url": "https://github.com/awslabs/aws-c-mqtt/archive/refs/tags/v0.13.3.tar.gz",
            "sha256": "1dfc11d6b3dc1a6d408df64073e8238739b4c50374078d36d3f2d30491d15527",
            "strip_prefix": "aws-c-mqtt-0.13.3"
        },
        "aws-c-s3": {
            "tag": "v0.11.5",
            "url": "https://github.com/awslabs/aws-c-s3/archive/refs/tags/v0.11.5.tar.gz",
            "sha256": "bc76ad6e4ef40703477cd2e411553b85216def71a0073cfe8b7fad8d3728b37c",
            "strip_prefix": "aws-c-s3-0.11.5"
        },
        "aws-c-sdkutils": {
            "tag": "v0.2.4",
            "url": "https://github.com/awslabs/aws-c-sdkutils/archive/refs/tags/v0.2.4.tar.gz",
            "sha256": "493cbed4fa57e0d4622fcff044e11305eb4fc12445f32c8861025597939175fc",
            "strip_prefix": "aws-c-sdkutils-0.2.4"
        },
        "aws-checksums": {
            "tag": "v0.2.9",
            "url": "https://github.com/awslabs/aws-checksums/archive/refs/tags/v0.2.9.tar.gz",
            "sha256": "eb59664a90ef8c09e595ee40daeb9d00ae32f2a75e4b93f2830df4bebdd68033",
            "strip_prefix": "aws-checksums-0.2.9"
        },
        "aws-lc": {
            "tag": "v1.66.2",
            "url": "https://github.com/awslabs/aws-lc/archive/refs/tags/v1.66.2.tar.gz",
            "sha256": "d64a46b4f75fa5362da412f1e96ff5b77eed76b3a95685651f81a558c5c9e126",
            "strip_prefix": "aws-lc-1.66.2"
        },
        "s2n": {
            "tag": "v1.6.4",
            "url": "https://github.com/awslabs/s2n/archive/refs/tags/v1.6.4.tar.gz",
            "sha256": "6874dcd366b32650bb00d3e94c4435b698bc47cadcba35d67e0d58cdbea6fbf5",
            "strip_prefix": "s2n-tls-1.6.4"
        },

    }

    for name, data in submodules.items():
        ctx.download_and_extract(
            url = data["url"],
            sha256 = data["sha256"],
            output = "crt/aws-crt-cpp/crt/" + name,
            stripPrefix = data["strip_prefix"],
        )

    # s2n headers are laid out as api/unstable in the source archive, but aws-c-io
    # includes them as <s2n/unstable/...>.
    ctx.symlink("crt/aws-crt-cpp/crt/s2n/api", "crt/aws-crt-cpp/crt/s2n/s2n")

    # 4. Inject BUILD files
    ctx.symlink(ctx.attr.bundled_build, "BUILD.bazel")
    ctx.symlink(ctx.attr.compiler_select, "compiler_select.bzl")

aws_sdk_repository = repository_rule(
    implementation = _aws_sdk_repository_impl,
    attrs = {
        "bundled_build": attr.label(),
        "compiler_select": attr.label(),
    },
)

def _aws_sdk_deps_impl(ctx):
    aws_sdk_repository(
        name = "aws_sdk_bundled",
        bundled_build = Label("//:bundled.BUILD"),
        compiler_select = Label("//:compiler_select.bzl"),
    )


aws_sdk_deps = module_extension(
    implementation = _aws_sdk_deps_impl,
)
