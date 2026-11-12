"""Public API for configuring jemalloc build settings."""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

# The empty string is a real prefix (none), so an unset jemalloc_prefix needs its own value.
_UNSET = "__unset__"

_REPO = Label("//:BUILD.bazel").repo_name

def _owned_by(owner, cc_info):
    """cc_info with this repository's linker inputs owned by owner instead of jemalloc's internal targets."""
    linker_inputs = [
        cc_common.create_linker_input(
            owner = owner,
            libraries = depset(linker_input.libraries),
            user_link_flags = linker_input.user_link_flags,
            additional_inputs = depset(linker_input.additional_inputs),
        ) if linker_input.owner.repo_name == _REPO else linker_input
        for linker_input in cc_info.linking_context.linker_inputs.to_list()
    ]

    # CcInfo has no public accessor for its debug context, the .dwo files of a fission build. rules_cc's Starlark CcInfo
    # (Bazel 9 and later) keeps it in _debug_context; Bazel's native CcInfo exposes nothing, so there it is dropped.
    debug_context = getattr(cc_info, "_debug_context", None)
    return CcInfo(
        compilation_context = cc_info.compilation_context,
        linking_context = cc_common.create_linking_context(linker_inputs = depset(linker_inputs, order = "topological")),
        **({"debug_context": debug_context} if debug_context else {})
    )

def _jemalloc_config_impl(ctx):
    target = ctx.attr._target[0]
    providers = [DefaultInfo, InstrumentedFilesInfo, OutputGroupInfo]

    return [target[provider] for provider in providers if provider in target] + [_owned_by(ctx.label, target[CcInfo])]

def _jemalloc_transition_impl(settings, attr):
    """Transition implementation that applies user-provided settings."""

    result = settings | {}

    # Boolean flags
    bool_flags = {
        "//settings/flags:enable_cache_oblivious": attr.cache_oblivious,
        "//settings/flags:enable_cxx": attr.cxx,
        "//settings/flags:enable_experimental_smallocx": attr.experimental_smallocx,
        "//settings/flags:enable_fill": attr.fill,
        "//settings/flags:enable_log": attr.log,
        "//settings/flags:enable_stats": attr.stats,
        "//settings/flags:enable_uaf_detection": attr.uaf_detection,
        "//settings/flags:enable_xmalloc": attr.xmalloc,
        "//settings/flags:without_export": attr.without_export,
    }
    for flag, value in bool_flags.items():
        if value == "True":
            result[flag] = True
        elif value == "False":
            result[flag] = False

    # String flags
    if attr.jemalloc_prefix != _UNSET:
        result["//settings/flags:jemalloc_prefix"] = attr.jemalloc_prefix

    if attr.lazy_lock != "":
        result["//settings/flags:enable_lazy_lock"] = attr.lazy_lock

    if attr.zone_allocator != "":
        result["//settings/flags:enable_zone_allocator"] = attr.zone_allocator

    # Integer flags
    if attr.lg_quantum != -1:
        result["//settings/flags:lg_quantum"] = attr.lg_quantum

    return result

_jemalloc_transition = transition(
    implementation = _jemalloc_transition_impl,
    inputs = [
        "//settings/flags:enable_cache_oblivious",
        "//settings/flags:enable_cxx",
        "//settings/flags:enable_experimental_smallocx",
        "//settings/flags:enable_fill",
        "//settings/flags:enable_lazy_lock",
        "//settings/flags:enable_log",
        "//settings/flags:enable_stats",
        "//settings/flags:enable_uaf_detection",
        "//settings/flags:enable_xmalloc",
        "//settings/flags:without_export",
        "//settings/flags:jemalloc_prefix",
        "//settings/flags:enable_zone_allocator",
        "//settings/flags:lg_quantum",
    ],
    outputs = [
        "//settings/flags:enable_cache_oblivious",
        "//settings/flags:enable_cxx",
        "//settings/flags:enable_experimental_smallocx",
        "//settings/flags:enable_fill",
        "//settings/flags:enable_lazy_lock",
        "//settings/flags:enable_log",
        "//settings/flags:enable_stats",
        "//settings/flags:enable_uaf_detection",
        "//settings/flags:enable_xmalloc",
        "//settings/flags:without_export",
        "//settings/flags:jemalloc_prefix",
        "//settings/flags:enable_zone_allocator",
        "//settings/flags:lg_quantum",
    ],
)

jemalloc = rule(
    doc = "Convenience rule that returns the jemalloc cc_library transitioned the optional build settings based on user-provided constraints. " +
          "An attribute left unset keeps the value of its //settings/flags setting.",
    implementation = _jemalloc_config_impl,
    attrs = {
        "cache_oblivious": attr.string(values = ["True", "False", ""]),
        "cxx": attr.string(values = ["True", "False", ""]),
        "experimental_smallocx": attr.string(values = ["True", "False", ""]),
        "fill": attr.string(values = ["True", "False", ""]),
        "jemalloc_prefix": attr.string(
            doc = "Prefix for the public API, as --with-jemalloc-prefix; \"\" for none, \"__auto__\" for configure's platform default.",
            default = _UNSET,
        ),
        "lazy_lock": attr.string(values = ["yes", "no", "__auto__", ""]),
        "lg_quantum": attr.int(default = -1),
        "log": attr.string(values = ["True", "False", ""]),
        "stats": attr.string(values = ["True", "False", ""]),
        "uaf_detection": attr.string(values = ["True", "False", ""]),
        "without_export": attr.string(values = ["True", "False", ""]),
        "xmalloc": attr.string(values = ["True", "False", ""]),
        "zone_allocator": attr.string(values = ["yes", "no", "__auto__"]),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_target": attr.label(
            doc = "The jemalloc cc_library target to configure.",
            default = "//:jemalloc",
            providers = [CcInfo],
            cfg = _jemalloc_transition,
        ),
    },
    provides = [CcInfo],
)
