"""Rules for pre-generated OpenSSL files."""

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
