"""This file gives a rule that forwards headers without their libraries."""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

visibility("private")

def _cc_headers_only_impl(ctx):
    merged = cc_common.merge_compilation_contexts(
        compilation_contexts = [dep[CcInfo].compilation_context for dep in ctx.attr.deps],
    )
    return [
        # The headers themselves, so building this target generates them.
        DefaultInfo(files = merged.headers),
        CcInfo(compilation_context = cc_common.create_compilation_context(
            framework_includes = merged.framework_includes,
            headers = merged.headers,
            includes = merged.includes,
            quote_includes = merged.quote_includes,
            system_includes = merged.system_includes,
        )),
    ]

cc_headers_only = rule(
    implementation = _cc_headers_only_impl,
    attrs = {
        "deps": attr.label_list(
            providers = [CcInfo],
            doc = "Libraries whose headers and include paths are forwarded.",
        ),
    },
    doc = """\
This rule gives the headers and include paths of `deps`, and nothing to link.

A cc_library dependency puts the archives of that dependency on every
downstream link line. SDL loads these libraries at runtime by soname, and
compiles only against their headers.

This rule also drops the defines of `deps`. Those defines belong to the builds
of those libraries. If a dependency starts to export a `HAVE_*` name, that name
changes the features that SDL compiles, and gives no warning.
""",
)
