"""Configuration-transition wrappers for the LLVM dep closure.

LLVM 17+ source uses C++17-only features (`std::string_view`, etc.)
in its public headers, but several BCR cc toolchains still default
the `--cxxopt` to `-std=c++14`. Without a transition, anything that
pulls in `@llvm-project//llvm:*` fails to compile on those
toolchains.

We solve it the same way `rules_ghdl` does: wrap the LLVM-consuming
target in a config transition that forces
`--cxxopt=-std=c++17` (and the matching `/std:c++17` for MSVC /
clang-cl) on both the target and exec configurations.

Vendored from rules_rust, via the BCR `ghdl` module:
https://github.com/bazelbuild/rules_rust/blob/main/extensions/bindgen/private/llvm_utils.bzl
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

# Per-platform `-std=c++17` spelling. MSVC / clang-cl use the `/std:`
# form; everyone else uses `-std=`.
_CXX_OPTS = select({
    "@rules_cc//cc/compiler:clang-cl": ["/std:c++17"],
    "@rules_cc//cc/compiler:msvc-cl": ["/std:c++17"],
    "//conditions:default": ["-std=c++17"],
})

_COMMON_ATTRS = {
    "cxxopts": attr.string_list(
        doc = "Flags to inject into `--host_cxxopt` and `--cxxopt` command line flags.",
        mandatory = True,
    ),
    "target": attr.label(
        doc = "The target to transition.",
        mandatory = True,
    ),
}

def _cc_stdcc17_transitioned_target_impl(ctx):
    """Forward the transitioned target's CcInfo / DefaultInfo /
    OutputGroupInfo without modification. The transition itself is
    applied via `cfg =` on the rule definition; this impl is a
    pass-through that re-exports the providers the consumer expects.
    """
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
    doc = "A rule to transition a C++ library to build with stdc++17.",
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
