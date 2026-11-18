"""brotli_dep"""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _brotli_copts_transition_impl(settings, attr):
    return {
        "//command_line_option:conlyopt": settings["//command_line_option:conlyopt"] + attr.conlyopts,
        "//command_line_option:copt": settings["//command_line_option:copt"] + attr.copts,
        "//command_line_option:cxxopt": settings["//command_line_option:cxxopt"] + attr.cxxopts,
        "//command_line_option:host_conlyopt": settings["//command_line_option:host_conlyopt"] + attr.conlyopts,
        "//command_line_option:host_copt": settings["//command_line_option:host_copt"] + attr.copts,
        "//command_line_option:host_cxxopt": settings["//command_line_option:host_cxxopt"] + attr.cxxopts,
    }

_brotli_copts_transition = transition(
    implementation = _brotli_copts_transition_impl,
    inputs = [
        "//command_line_option:copt",
        "//command_line_option:host_copt",
        "//command_line_option:conlyopt",
        "//command_line_option:host_conlyopt",
        "//command_line_option:cxxopt",
        "//command_line_option:host_cxxopt",
    ],
    outputs = [
        "//command_line_option:copt",
        "//command_line_option:host_copt",
        "//command_line_option:conlyopt",
        "//command_line_option:host_conlyopt",
        "//command_line_option:cxxopt",
        "//command_line_option:host_cxxopt",
    ],
)

def _brotli_dep_impl(ctx):
    target = ctx.attr.dep[0]

    providers = [target[CcInfo]]

    if OutputGroupInfo in target:
        providers.append(target[OutputGroupInfo])

    if InstrumentedFilesInfo in target:
        providers.append(target[InstrumentedFilesInfo])

    if DefaultInfo in target:
        providers.append(target[DefaultInfo])

    return providers

brotli_dep = rule(
    doc = """\
Transition that suppresses warnings when building brotli.

Brotli's upstream BUILD.bazel enables -Werror, which fails on some
compilers (e.g. GCC 9 aarch64 triggers -Wsign-conversion in
matching_tag_mask.h).  Brotli's own BCR presubmit works around this
with --copt=-Wno-error=sign-conversion and similar flags, but
consumers don't inherit those.  This transition applies the same
flags so brotli builds cleanly as a transitive dependency.
""",
    implementation = _brotli_dep_impl,
    attrs = {
        "conlyopts": attr.string_list(
            doc = "Extra flags appended to --conlyopt and --host_conlyopt.",
            default = [],
        ),
        "copts": attr.string_list(
            doc = "Extra flags appended to --copt and --host_copt.",
            default = [],
        ),
        "cxxopts": attr.string_list(
            doc = "Extra flags appended to --cxxopt and --host_cxxopt.",
            default = [],
        ),
        "dep": attr.label(
            doc = "The brotli cc_library target to wrap.",
            cfg = _brotli_copts_transition,
            providers = [CcInfo],
        ),
        "_allowlist_function_transition": attr.label(
            default = Label("@bazel_tools//tools/allowlists/function_transition_allowlist"),
        ),
    },
)
