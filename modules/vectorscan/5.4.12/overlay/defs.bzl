"""Header-only dependency context for Vectorscan's use of Boost."""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _cc_compile_context_impl(ctx):
    return [CcInfo(compilation_context = ctx.attr.dep[CcInfo].compilation_context)]

cc_compile_context = rule(
    implementation = _cc_compile_context_impl,
    attrs = {"dep": attr.label(providers = [CcInfo])},
)
