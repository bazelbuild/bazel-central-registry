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
        CcInfo(compilation_context = merged),
    ]

cc_headers_only = rule(
    implementation = _cc_headers_only_impl,
    attrs = {
        "deps": attr.label_list(
            providers = [CcInfo],
            doc = "Libraries whose compilation contexts are forwarded.",
        ),
    },
    doc = """\
This rule gives the compilation context of `deps`, and nothing to link.

A cc_library dependency puts the archives of that dependency on every
downstream link line. SDL loads these libraries at runtime by soname, and
compiles only against their headers.

The rule forwards the context as it is. With the external_include_paths
feature, rules_cc moves each search path of another repository to
external_includes, and create_compilation_context takes that parameter only
from rules_cc itself. The paths keep their kind, so they still follow SDL's
own, and SDL's generated wayland-client-protocol.h still wins over the wayland
module's. See wayland_protocols.bzl.

The defines of `deps` come with the context. They are XCMSDIR and XLOCALELIBDIR
of libx11, which SDL does not read. A `HAVE_*` name from a dependency would
change the features that SDL compiles, and give no warning.
""",
)
