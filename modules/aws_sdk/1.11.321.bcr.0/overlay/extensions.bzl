def _aws_sdk_repository_impl(ctx):
    # 1. Download aws-sdk-cpp (Main)
    ctx.download_and_extract(
        url = "https://github.com/aws/aws-sdk-cpp/archive/refs/tags/1.11.321.tar.gz",
        sha256 = "482bc4e0b89874a90be0ce71d7b3ccb0289f5ab5a94e802c7265f431d87134df",
        stripPrefix = "aws-sdk-cpp-1.11.321",
    )

    # 2. Download aws-crt-cpp
    ctx.download_and_extract(
        url = "https://github.com/awslabs/aws-crt-cpp/archive/refs/tags/v0.26.8.tar.gz",
        sha256 = "36ced4fb54c8eb7325b4576134e01f93bfaca2709565b5ad036d198d703e4c8f",
        output = "crt/aws-crt-cpp",
        stripPrefix = "aws-crt-cpp-0.26.8",
    )

    # 3. Download submodules into crt/aws-crt-cpp/crt/
    submodules = {
        "aws-c-auth": {
            "tag": "v0.7.16",
            "url": "https://github.com/awslabs/aws-c-auth/archive/refs/tags/v0.7.16.tar.gz",
            "sha256": "7ee5afe05482f750dd0406b8b5b55dafb446fc21288f98c0b4118d62795003ba",
            "strip_prefix": "aws-c-auth-0.7.16"
        },
        "aws-c-cal": {
            "tag": "v0.6.11",
            "url": "https://github.com/awslabs/aws-c-cal/archive/refs/tags/v0.6.11.tar.gz",
            "sha256": "e1b0af88c14300e125e86ee010d4c731292851fff16cfb67eb6ba6036df2d648",
            "strip_prefix": "aws-c-cal-0.6.11"
        },
        "aws-c-common": {
            "tag": "v0.9.15",
            "url": "https://github.com/awslabs/aws-c-common/archive/refs/tags/v0.9.15.tar.gz",
            "sha256": "8f36c7a6a5d2e17365759d15591f800d3e76dcaa34a226389b92647cbd92393a",
            "strip_prefix": "aws-c-common-0.9.15"
        },
        "aws-c-compression": {
            "tag": "v0.2.18",
            "url": "https://github.com/awslabs/aws-c-compression/archive/refs/tags/v0.2.18.tar.gz",
            "sha256": "517c361f3b7fffca08efd5ad251a20489794f056eab0dfffacc6d5b341df8e86",
            "strip_prefix": "aws-c-compression-0.2.18"
        },
        "aws-c-event-stream": {
            "tag": "v0.4.2",
            "url": "https://github.com/awslabs/aws-c-event-stream/archive/refs/tags/v0.4.2.tar.gz",
            "sha256": "c98b8fa05c2ca10aacfce7327b92a84669c2da95ccb8e7d7b3e3285fcec8beee",
            "strip_prefix": "aws-c-event-stream-0.4.2"
        },
        "aws-c-http": {
            "tag": "v0.8.1",
            "url": "https://github.com/awslabs/aws-c-http/archive/refs/tags/v0.8.1.tar.gz",
            "sha256": "83fb47e2d7956469bb328f16dea96663e96f8f20dc60dc4e9676b82804588530",
            "strip_prefix": "aws-c-http-0.8.1"
        },
        "aws-c-io": {
            "tag": "v0.14.7",
            "url": "https://github.com/awslabs/aws-c-io/archive/refs/tags/v0.14.7.tar.gz",
            "sha256": "ecf1f660d7d43913aa8a416be6a2027101ce87c3b241344342d608335b4df7d4",
            "strip_prefix": "aws-c-io-0.14.7"
        },
        "aws-c-mqtt": {
            "tag": "v0.10.3",
            "url": "https://github.com/awslabs/aws-c-mqtt/archive/refs/tags/v0.10.3.tar.gz",
            "sha256": "bb938d794b0757d669b5877526363dc6f6f0e43869ca19fc196ffd0f7a35f5b9",
            "strip_prefix": "aws-c-mqtt-0.10.3"
        },
        "aws-c-s3": {
            "tag": "v0.5.5",
            "url": "https://github.com/awslabs/aws-c-s3/archive/refs/tags/v0.5.5.tar.gz",
            "sha256": "81d3913826953cb634ef1183a0c241d5e117419a877b625d69d7e1e54bbe5219",
            "strip_prefix": "aws-c-s3-0.5.5"
        },
        "aws-c-sdkutils": {
            "tag": "v0.1.15",
            "url": "https://github.com/awslabs/aws-c-sdkutils/archive/refs/tags/v0.1.15.tar.gz",
            "sha256": "15fa30b8b0a357128388f2f40ab0ba3df63742fd333cc2f89cb91a9169f03bdc",
            "strip_prefix": "aws-c-sdkutils-0.1.15"
        },
        "aws-checksums": {
            "tag": "v0.1.18",
            "url": "https://github.com/awslabs/aws-checksums/archive/refs/tags/v0.1.18.tar.gz",
            "sha256": "bdba9d0a8b8330a89c6b8cbc00b9aa14f403d3449b37ff2e0d96d62a7301b2ee",
            "strip_prefix": "aws-checksums-0.1.18"
        },
        "aws-lc": {
            "tag": "v1.23.0",
            "url": "https://github.com/awslabs/aws-lc/archive/refs/tags/v1.23.0.tar.gz",
            "sha256": "e508a40cd4fe0a38b0a29454d4a7bdb2df170484314e7ba65ecc11409f65ded2",
            "strip_prefix": "aws-lc-1.23.0"
        },
        "s2n": {
            "tag": "v1.4.11",
            "url": "https://github.com/awslabs/s2n/archive/refs/tags/v1.4.11.tar.gz",
            "sha256": "82650a16ed3523aafe33c289dfe316df4a53d73c4d732a90d5e8f30e93a952a2",
            "strip_prefix": "s2n-tls-1.4.11"
        },

    }

    for name, data in submodules.items():
        ctx.download_and_extract(
            url = data["url"],
            sha256 = data["sha256"],
            output = "crt/aws-crt-cpp/crt/" + name,
            stripPrefix = data["strip_prefix"],
        )

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
