"""Rules and macros for pre-generated OpenSSL files."""

load("//bazel/constants:generated_srcs.bzl", "COMMON_GENERATED_CRYPTO_SRCS", "GENERATED_CRYPTO_EXTRA_SRCS")

_PREGEN_PLATFORMS = [
    "android_arm64",
    "android_x86_64",
    "darwin_arm64",
    "darwin_x86_64",
    "freebsd_aarch64",
    "freebsd_x86_64",
    "ios_arm64",
    "linux_aarch64",
    "linux_arm",
    "linux_ppc64le",
    "linux_riscv64",
    "linux_s390x",
    "linux_x86_64",
    "windows_arm64",
    "windows_x64",
]

def _strip_prefix(path, prefix):
    parts = path.split(prefix, 1)
    if len(parts) != 2:
        fail("Cannot find prefix '{}' in '{}'".format(prefix, path))
    return parts[1]

def _pregen_files_impl(ctx):
    crypto_outs = []
    app_outs = []

    # Files under apps/ (progs.*, and on 4.1+ apps/include/configuration.h,
    # which varies by platform) belong to the openssl binary.
    for srcs, prefix in [
        (ctx.files.common_srcs, ctx.attr.common_prefix),
        (ctx.files.platform_srcs, ctx.attr.platform_prefix),
    ]:
        for src in srcs:
            canonical = _strip_prefix(src.short_path, prefix)
            out = ctx.actions.declare_file(canonical)
            ctx.actions.symlink(output = out, target_file = src)
            (app_outs if canonical.startswith("apps/") else crypto_outs).append(out)

    return [
        DefaultInfo(files = depset(crypto_outs)),
        OutputGroupInfo(app = depset(app_outs)),
    ]

pregen_files = rule(
    implementation = _pregen_files_impl,
    doc = """Symlinks pre-generated overlay files to canonical OpenSSL output paths.

Produces outputs at the same paths as the Perl genrule fallback
(e.g. include/openssl/bio.h, crypto/buildinf.h, apps/progs.h) so
downstream cc_library targets can switch between pregen and Perl via
select() without changing include paths.

Files whose canonical path starts with "apps/" are placed in the "app"
output group; all others appear in DefaultInfo.""",
    attrs = {
        "common_prefix": attr.string(
            doc = "Path prefix to strip from common_srcs entries.",
            default = "generated/common/",
        ),
        "common_srcs": attr.label_list(
            doc = "Platform-independent source files under generated/common/. " +
                  "The common_prefix is stripped from each path to derive the " +
                  "canonical output location.",
            allow_files = True,
        ),
        "platform_prefix": attr.string(
            doc = "Path prefix to strip from platform_srcs entries. Must match " +
                  "the directory used in platform_srcs (e.g. 'generated/darwin_arm64/'). " +
                  "Typically wrapped in a select() parallel to platform_srcs.",
            default = "",
        ),
        "platform_srcs": attr.label_list(
            doc = "Platform-specific source files (e.g. configuration.h) under " +
                  "a generated/<platform>/ directory. Typically wrapped in a " +
                  "select() keyed on platform config_settings.",
            allow_files = True,
        ),
    },
)

# buildifier: disable=unnamed-macro
def pregen_filegroups():
    """Create filegroup targets in the @openssl_pregen archive.

    Exposes the raw generated files so that pregen_files rules in the
    @openssl overlay can consume them as label inputs.
    """

    # Everything in the archive is derived from OpenSSL sources, so the
    # generator ships OpenSSL's LICENSE.txt alongside them.
    native.exports_files(["LICENSE.txt"])

    # Globs are deliberately broad: the set of generated files (and where
    # they live) changes between OpenSSL versions, and the generator already
    # decided what belongs in common/ versus a per-platform directory.
    #
    # Generated sources are referenced one by one from pregen_overlay_targets
    # (so each configuration compiles only its own set), which requires them
    # to be exported.
    native.exports_files(native.glob(
        ["generated/common/**/*.c"],
        allow_empty = True,
    ))
    native.filegroup(
        name = "common_hdrs",
        srcs = native.glob(
            [
                "generated/common/**/*.h",
                "generated/common/**/*.inc",
            ],
            allow_empty = True,
        ),
    )
    for plat in _PREGEN_PLATFORMS + ["no_asm"]:
        native.filegroup(
            name = plat + "_hdrs",
            srcs = native.glob(
                [
                    "generated/" + plat + "/**/*.h",
                    "generated/" + plat + "/**/*.inc",
                ],
                allow_empty = True,
            ),
        )

    # One group per directory the generator writes under generated/asm/
    # (_PERLASM_FLAVORS in generate_constants.py).
    for flavor in ["elf", "ios64", "linux32", "linux64", "linux64le", "macosx", "masm", "riscv64", "s390x", "win64"]:
        native.filegroup(
            name = "asm_" + flavor,
            srcs = native.glob(
                ["generated/asm/" + flavor + "/**"],
                allow_empty = True,
            ),
        )

# buildifier: disable=unnamed-macro
def pregen_overlay_targets():
    """Create pregen targets in @openssl consuming files from @openssl_pregen.

    The pregen_files rules run inside @openssl so that declare_file
    places outputs in @openssl's tree, making the existing cc_library
    includes work without any additional include-path plumbing.
    """
    platform_prefix = {
        "//configs:" + p: "generated/" + p + "/"
        for p in _PREGEN_PLATFORMS
    }
    platform_prefix["//conditions:default"] = "generated/no_asm/"

    platform_srcs = {
        "//configs:" + p: ["@openssl_pregen//:" + p + "_hdrs"]
        for p in _PREGEN_PLATFORMS
    }
    platform_srcs["//conditions:default"] = ["@openssl_pregen//:no_asm_hdrs"]

    pregen_files(
        name = "pregen_hdrs",
        common_srcs = ["@openssl_pregen//:common_hdrs"],
        platform_prefix = select(platform_prefix),
        platform_srcs = select(platform_srcs),
        tags = ["manual"],
    )

    # Generated .c files are referenced individually (not via a glob) so each
    # configuration compiles exactly the set Configure lists for it; this
    # mirrors the libcrypto srcs select in //:BUILD.
    def pregen_src_labels(outputs):
        return ["@openssl_pregen//:generated/common/" + out for out in outputs]

    no_asm_srcs = COMMON_GENERATED_CRYPTO_SRCS + GENERATED_CRYPTO_EXTRA_SRCS["no_asm"]
    generated_srcs = {
        "//configs:_asm_" + config: pregen_src_labels(COMMON_GENERATED_CRYPTO_SRCS + extra)
        for config, extra in GENERATED_CRYPTO_EXTRA_SRCS.items()
        if config != "no_asm"
    }
    generated_srcs["//configs:_no_asm_fallback"] = pregen_src_labels(no_asm_srcs)
    generated_srcs["//conditions:default"] = pregen_src_labels(no_asm_srcs)

    pregen_files(
        name = "pregen_srcs",
        common_srcs = ["@openssl_pregen//:generated/common/apps/progs.c"] + select(generated_srcs),
        tags = ["manual"],
    )
    native.filegroup(name = "pregen_app_hdrs", srcs = [":pregen_hdrs"], output_group = "app", tags = ["manual"])
    native.filegroup(name = "pregen_app_srcs", srcs = [":pregen_srcs"], output_group = "app", tags = ["manual"])
