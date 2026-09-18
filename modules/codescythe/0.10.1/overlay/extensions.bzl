"""Download and register platform-specific Codescythe binaries."""

_PLATFORMS = {
    "darwin_arm64": struct(
        asset = "codescythe-darwin-arm64",
        constraints = ["@platforms//os:macos", "@platforms//cpu:arm64"],
    ),
    "linux_amd64": struct(
        asset = "codescythe-linux-amd64",
        constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
    ),
    "linux_arm64": struct(
        asset = "codescythe-linux-arm64",
        constraints = ["@platforms//os:linux", "@platforms//cpu:arm64"],
    ),
}

def _codescythe_repository_impl(repository_ctx):
    release_url = "https://github.com/perplexityai/codescythe/releases/download/codescythe_cli_v{}".format(repository_ctx.attr.version)
    repository_ctx.download(
        url = release_url + "/checksums.txt",
        output = "checksums.txt",
    )

    checksum = None
    for line in repository_ctx.read("checksums.txt").splitlines():
        fields = [field for field in line.split(" ") if field]
        if len(fields) == 2 and fields[1] == repository_ctx.attr.asset:
            checksum = fields[0]
            break

    if checksum == None:
        fail("No checksum found for {} in release {}".format(
            repository_ctx.attr.asset,
            repository_ctx.attr.version,
        ))

    repository_ctx.download(
        url = release_url + "/" + repository_ctx.attr.asset,
        output = "codescythe",
        sha256 = checksum,
        executable = True,
    )
    repository_ctx.file(
        "BUILD.bazel",
        'exports_files(["codescythe"], visibility = ["//visibility:public"])\n',
    )

_codescythe_repository = repository_rule(
    implementation = _codescythe_repository_impl,
    attrs = {
        "asset": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
    },
)

def _codescythe_toolchains_repository_impl(repository_ctx):
    lines = [
        'load("@codescythe//:toolchain.bzl", "codescythe_toolchain")',
        "",
        'package(default_visibility = ["//visibility:public"])',
        "",
    ]

    for name, platform in _PLATFORMS.items():
        lines.extend([
            "codescythe_toolchain(",
            '    name = "{}_toolchain_impl",'.format(name),
            '    codescythe = "@codescythe_{}//:codescythe",'.format(name),
            ")",
            "",
            "toolchain(",
            '    name = "{}_toolchain",'.format(name),
            "    exec_compatible_with = {},".format(repr(platform.constraints)),
            '    toolchain = ":{}_toolchain_impl",'.format(name),
            '    toolchain_type = "@codescythe//:toolchain_type",',
            ")",
            "",
        ])

    repository_ctx.file("BUILD.bazel", "\n".join(lines))

_codescythe_toolchains_repository = repository_rule(
    implementation = _codescythe_toolchains_repository_impl,
)

def _codescythe_impl(module_ctx):
    version = None
    for module in module_ctx.modules:
        if module.name == "codescythe":
            version = module.version

    for module in module_ctx.modules:
        for settings in module.tags.toolchain:
            if settings.version:
                version = settings.version

    if not version:
        fail("Could not determine the Codescythe release version")

    for name, platform in _PLATFORMS.items():
        _codescythe_repository(
            name = "codescythe_" + name,
            asset = platform.asset,
            version = version,
        )

    _codescythe_toolchains_repository(name = "codescythe_toolchains")

codescythe = module_extension(
    implementation = _codescythe_impl,
    tag_classes = {
        "toolchain": tag_class(attrs = {"version": attr.string()}),
    },
)
