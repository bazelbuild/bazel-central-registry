"""Rules and macros for pre-generated OpenSSL files."""

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

    for src in ctx.files.common_srcs:
        canonical = _strip_prefix(src.short_path, ctx.attr.common_prefix)
        out = ctx.actions.declare_file(canonical)
        ctx.actions.symlink(output = out, target_file = src)
        if canonical.startswith("apps/"):
            app_outs.append(out)
        else:
            crypto_outs.append(out)

    prefix = ctx.attr.platform_prefix
    for src in ctx.files.platform_srcs:
        canonical = _strip_prefix(src.short_path, prefix)
        out = ctx.actions.declare_file(canonical)
        ctx.actions.symlink(output = out, target_file = src)
        crypto_outs.append(out)

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
    native.filegroup(
        name = "common_hdrs",
        srcs = native.glob([
            "generated/common/include/**/*.h",
            "generated/common/providers/common/include/**/*.h",
        ]) + [
            "generated/common/crypto/buildinf.h",
            "generated/common/apps/progs.h",
        ],
    )
    native.filegroup(
        name = "common_srcs",
        srcs = native.glob([
            "generated/common/crypto/**/*.c",
            "generated/common/providers/**/*.c",
        ]) + ["generated/common/apps/progs.c"],
    )
    for plat in _PREGEN_PLATFORMS:
        native.filegroup(
            name = plat + "_hdrs",
            srcs = native.glob(["generated/" + plat + "/include/**/*.h"]),
        )
    native.filegroup(
        name = "no_asm_hdrs",
        srcs = native.glob(["generated/no_asm/include/**/*.h"]),
    )
    for flavor in ["elf", "ios64", "linux64", "macosx"]:
        native.filegroup(
            name = "asm_" + flavor,
            srcs = native.glob(["generated/asm/" + flavor + "/**"]),
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
    pregen_files(
        name = "pregen_srcs",
        common_srcs = ["@openssl_pregen//:common_srcs"],
        tags = ["manual"],
    )
    native.filegroup(name = "pregen_app_hdrs", srcs = [":pregen_hdrs"], output_group = "app", tags = ["manual"])
    native.filegroup(name = "pregen_app_srcs", srcs = [":pregen_srcs"], output_group = "app", tags = ["manual"])
