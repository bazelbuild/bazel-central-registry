"""Configuration-transition wrapper for forcing C++17 on a dep closure.

icu's public headers use C++17 type traits (`std::is_same_v`,
`std::void_t`, etc.). The Bazel cc toolchain defaults `--cxxopt` to
`-std=c++14` on many platforms (notably macOS Xcode 26), so anything
that compiles icu sources needs the standard pushed up.

Rather than relying on every consumer to set `--cxxopt=-std=c++17`
globally, we wrap the icu dep aggregator in a transition that forces
the flag onto both the target and exec configurations. Adapted from
the `rules_ghdl` and `nvc` BCR modules, which apply the same pattern
to the LLVM dep closure (hence the file name).
"""

load("@rules_cc//cc:defs.bzl", "CcInfo")

def _cc_stdcc17_transition_impl(settings, attr):
    """Force `-std=c++17` onto both target and exec configurations."""
    host_opt = settings["//command_line_option:host_cxxopt"]
    tgt_opt = settings["//command_line_option:cxxopt"]

    host_opt.extend(attr.cxxopts)
    tgt_opt.extend(attr.cxxopts)

    return {
        "//command_line_option:cxxopt": tgt_opt,
        "//command_line_option:host_cxxopt": host_opt,
    }

_cc_stdcc17_transition = transition(
    implementation = _cc_stdcc17_transition_impl,
    inputs = [
        "//command_line_option:host_cxxopt",
        "//command_line_option:cxxopt",
    ],
    outputs = [
        "//command_line_option:host_cxxopt",
        "//command_line_option:cxxopt",
    ],
)

# Per-toolchain spelling: MSVC / clang-cl use `/std:`, everyone else `-std=`.
_CXX_OPTS = select({
    "@rules_cc//cc/compiler:clang-cl": ["/std:c++17"],
    "@rules_cc//cc/compiler:msvc-cl": ["/std:c++17"],
    "//conditions:default": ["-std=c++17"],
})

_COMMON_ATTRS = {
    "cxxopts": attr.string_list(
        doc = "Flags injected into `--host_cxxopt` and `--cxxopt`.",
        mandatory = True,
    ),
    "target": attr.label(
        doc = "The target to transition.",
        mandatory = True,
    ),
}

def _cc_stdcc17_transitioned_target_impl(ctx):
    """Forward the transitioned target's providers unchanged."""
    providers = []

    if CcInfo in ctx.attr.target:
        providers.append(ctx.attr.target[CcInfo])

    if DefaultInfo in ctx.attr.target:
        info = ctx.attr.target[DefaultInfo]
        kwargs = {
            "files": info.files,
            "runfiles": info.default_runfiles,
        }

        if info.files_to_run and info.files_to_run.executable:
            exe = info.files_to_run.executable
            kwargs["executable"] = ctx.actions.declare_file(
                "{}.{}".format(ctx.label.name, exe.extension).rstrip("."),
            )
            ctx.actions.symlink(
                output = kwargs["executable"],
                target_file = exe,
                is_executable = True,
            )

        providers.append(DefaultInfo(**kwargs))

    if OutputGroupInfo in ctx.attr.target:
        providers.append(ctx.attr.target[OutputGroupInfo])

    return providers

_cc_stdcc17_transitioned_library = rule(
    doc = "Wrap `target` so its dep closure is built with C++17.",
    implementation = _cc_stdcc17_transitioned_target_impl,
    cfg = _cc_stdcc17_transition,
    attrs = _COMMON_ATTRS,
)

def cc_stdcc17_transitioned_library(name, **kwargs):
    """Wrap `target` so its dependency closure is built with C++17."""
    _cc_stdcc17_transitioned_library(
        name = name,
        cxxopts = _CXX_OPTS,
        **kwargs
    )
