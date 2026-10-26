"""Expose OpenMP build inputs without leaking its CcInfo to consumers."""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _linking_only_impl(ctx):
    return [CcInfo(linking_context = ctx.attr.dep[CcInfo].linking_context)]

linking_only = rule(
    implementation = _linking_only_impl,
    attrs = {"dep": attr.label(mandatory = True, providers = [CcInfo])},
)

def _openmp_header_impl(ctx):
    headers = [
        header
        for header in ctx.attr.dep[CcInfo].compilation_context.headers.to_list()
        if header.basename == "omp.h"
    ]
    if len(headers) != 1:
        fail("Expected one OpenMP header, got %s" % headers)
    return [
        DefaultInfo(files = depset(headers)),
        CcInfo(compilation_context = cc_common.create_compilation_context(
            headers = depset(headers),
            system_includes = depset([headers[0].dirname]),
        )),
    ]

openmp_header = rule(
    implementation = _openmp_header_impl,
    attrs = {"dep": attr.label(mandatory = True, providers = [CcInfo])},
)
