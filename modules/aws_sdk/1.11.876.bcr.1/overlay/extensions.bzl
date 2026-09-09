def _aws_sdk_repository_impl(ctx):
    # 1. Download aws-sdk-cpp (Main)
    ctx.download_and_extract(
        url = "https://github.com/aws/aws-sdk-cpp/archive/refs/tags/1.11.876.tar.gz",
        sha256 = "68a885628b068d30311c041ee1a697e2e364308768ac1b40be5a3eee82831ee8",
        stripPrefix = "aws-sdk-cpp-1.11.876",
    )

    # 2. Download aws-crt-cpp
    ctx.download_and_extract(
        url = "https://github.com/awslabs/aws-crt-cpp/archive/refs/tags/v0.43.4.tar.gz",
        sha256 = "59e508878c5809b446bbe035ac71ea42c6e3b12978bcc2705a01490d1ba62577",
        output = "crt/aws-crt-cpp",
        stripPrefix = "aws-crt-cpp-0.43.4",
    )

    # 3. Download submodules into crt/aws-crt-cpp/crt/
    submodules = {
        "aws-c-auth": {
            "tag": "v0.10.4",
            "url": "https://github.com/awslabs/aws-c-auth/archive/refs/tags/v0.10.4.tar.gz",
            "sha256": "6fb567f496a450d4b6d3f5749d735977a0156957e8ccbca9af7a5ee15d1ffda7",
            "strip_prefix": "aws-c-auth-0.10.4"
        },
        "aws-c-cal": {
            "tag": "v0.9.15",
            "url": "https://github.com/awslabs/aws-c-cal/archive/refs/tags/v0.9.15.tar.gz",
            "sha256": "215dd31c12ea49c4f40aa7882a800f9648e4095cfcb2d6abdd27e957574ad6e2",
            "strip_prefix": "aws-c-cal-0.9.15"
        },
        "aws-c-common": {
            "tag": "v0.14.3",
            "url": "https://github.com/awslabs/aws-c-common/archive/refs/tags/v0.14.3.tar.gz",
            "sha256": "6ecbc5d8d086fb2218f6e1be4d643a6eccf8ee20b2a52055758377b06f0c2ad2",
            "strip_prefix": "aws-c-common-0.14.3"
        },
        "aws-c-compression": {
            "tag": "v0.3.2",
            "url": "https://github.com/awslabs/aws-c-compression/archive/refs/tags/v0.3.2.tar.gz",
            "sha256": "f93f5a5d8b3fee3a6d97b14ba279efacd4d4016ef9cc7dc4be7d43519ecfbe93",
            "strip_prefix": "aws-c-compression-0.3.2"
        },
        "aws-c-event-stream": {
            "tag": "v0.7.1",
            "url": "https://github.com/awslabs/aws-c-event-stream/archive/refs/tags/v0.7.1.tar.gz",
            "sha256": "334b2abfe0cb5c68d79d52525598fdd5f6052b93a17a78a4b1ada7fa1be252c0",
            "strip_prefix": "aws-c-event-stream-0.7.1"
        },
        "aws-c-http": {
            "tag": "v0.11.0",
            "url": "https://github.com/awslabs/aws-c-http/archive/refs/tags/v0.11.0.tar.gz",
            "sha256": "4ccbdd33c798b590288330dec9e93abe2ff6cfb198b7a4db036c9d362f2e6506",
            "strip_prefix": "aws-c-http-0.11.0"
        },
        "aws-c-io": {
            "tag": "v0.27.5",
            "url": "https://github.com/awslabs/aws-c-io/archive/refs/tags/v0.27.5.tar.gz",
            "sha256": "aa132d5a728f18ab8e0a6ea96d3d2f7e66bc8d3fe029d9ed1b05c06aa0c5b900",
            "strip_prefix": "aws-c-io-0.27.5"
        },
        "aws-c-mqtt": {
            "tag": "v0.16.0",
            "url": "https://github.com/awslabs/aws-c-mqtt/archive/refs/tags/v0.16.0.tar.gz",
            "sha256": "9bc044a9c2f0d80c384ae6a6907c8817e0b40f673f75c4615c83b20f83140374",
            "strip_prefix": "aws-c-mqtt-0.16.0"
        },
        "aws-c-s3": {
            "tag": "v0.13.2",
            "url": "https://github.com/awslabs/aws-c-s3/archive/refs/tags/v0.13.2.tar.gz",
            "sha256": "45341000a41e853e8ea440684d8848a74d47422d121493b22590ddb0c1c7f140",
            "strip_prefix": "aws-c-s3-0.13.2"
        },
        "aws-c-sdkutils": {
            "tag": "v0.2.9",
            "url": "https://github.com/awslabs/aws-c-sdkutils/archive/refs/tags/v0.2.9.tar.gz",
            "sha256": "14fe900f80c3b9f5e53a783d9ac0865ed9ba1ae63b67744b9f82a8b3194a4388",
            "strip_prefix": "aws-c-sdkutils-0.2.9"
        },
        "aws-checksums": {
            "tag": "v0.2.10",
            "url": "https://github.com/awslabs/aws-checksums/archive/refs/tags/v0.2.10.tar.gz",
            "sha256": "cb6509f75e42ee25c372a6d379e8582ce5179e5335183842e808f7d8abb0c314",
            "strip_prefix": "aws-checksums-0.2.10"
        },
        "s2n": {
            "tag": "v1.7.6",
            "url": "https://github.com/aws/s2n-tls/archive/refs/tags/v1.7.6.tar.gz",
            "sha256": "31b7a6cc287799327fb414072d6d71168daa859939898726f84ca54fc6e45c3b",
            "strip_prefix": "s2n-tls-1.7.6"
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
