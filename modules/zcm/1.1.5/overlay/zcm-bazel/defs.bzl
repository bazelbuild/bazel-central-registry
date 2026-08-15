"""Bazel rules for ZeroCM message generation."""

load("@rules_cc//cc:defs.bzl", "cc_library")

# ==============================================================================
# C Message Generation
# ==============================================================================

def _zcm_c_library_srcs_impl(ctx):
    out_hdrs = [
        ctx.actions.declare_file(src.basename[:-4] + ".h")
        for src in ctx.files.srcs
    ]
    out_srcs = [
        ctx.actions.declare_file(src.basename[:-4] + ".c")
        for src in ctx.files.srcs
    ]

    hpath = (
        ctx.bin_dir.path
        if not ctx.attr.unpackaged
        else (ctx.bin_dir.path + "/" + ctx.label.package if ctx.label.package else ctx.bin_dir.path)
    )

    args = ctx.actions.args()
    args.add("--c")
    args.add("--c-hpath", hpath)
    args.add("--c-cpath", hpath)
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        inputs = ctx.files.srcs,
        outputs = out_hdrs + out_srcs,
        executable = ctx.executable._zcm_gen,
        arguments = [args],
        mnemonic = "ZcmGenC",
        progress_message = "Generating ZCM C sources for %s" % ctx.label,
    )
    return [
        DefaultInfo(files = depset(out_srcs + out_hdrs)),
        OutputGroupInfo(hdrs = out_hdrs, srcs = out_srcs),
    ]

zcm_c_library_srcs = rule(
    implementation = _zcm_c_library_srcs_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".zcm"], mandatory = True),
        "unpackaged": attr.bool(default = False),
        "_zcm_gen": attr.label(
            default = Label("//:zcm-gen"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def zcm_c_library(name, srcs = [], deps = [], unpackaged = False, includes = [], visibility = None, **kwargs):
    """Convenience macro generating a cc_library with generated ZCM C sources and headers."""
    srcs_target = "%s_gen_srcs" % name
    zcm_c_library_srcs(
        name = srcs_target,
        srcs = srcs,
        unpackaged = unpackaged,
        visibility = ["//visibility:private"],
    )

    cc_library(
        name = name,
        srcs = [":" + srcs_target],
        hdrs = [":" + srcs_target],
        includes = includes,
        deps = [Label("//:zcm")] + deps,
        visibility = visibility,
        **kwargs
    )

# ==============================================================================
# C++ Message Generation
# ==============================================================================

def _zcm_cc_library_srcs_impl(ctx):
    out_hdrs = [
        ctx.actions.declare_file(src.basename[:-4] + ".hpp")
        for src in ctx.files.srcs
    ]

    hpath = (
        ctx.bin_dir.path
        if not ctx.attr.unpackaged
        else (ctx.bin_dir.path + "/" + ctx.label.package if ctx.label.package else ctx.bin_dir.path)
    )

    args = ctx.actions.args()
    args.add("--cpp")
    args.add("--cpp-hpath", hpath)
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        inputs = ctx.files.srcs,
        outputs = out_hdrs,
        executable = ctx.executable._zcm_gen,
        arguments = [args],
        mnemonic = "ZcmGenCpp",
        progress_message = "Generating ZCM C++ headers for %s" % ctx.label,
    )
    return [DefaultInfo(files = depset(out_hdrs))]

zcm_cc_library_srcs = rule(
    implementation = _zcm_cc_library_srcs_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".zcm"], mandatory = True),
        "unpackaged": attr.bool(default = False),
        "_zcm_gen": attr.label(
            default = Label("//:zcm-gen"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def zcm_cc_library(name, srcs = [], deps = [], unpackaged = False, includes = [], visibility = None, **kwargs):
    """Convenience macro generating a cc_library with generated ZCM C++ headers."""
    srcs_target = "%s_gen_srcs" % name
    zcm_cc_library_srcs(
        name = srcs_target,
        srcs = srcs,
        unpackaged = unpackaged,
        visibility = ["//visibility:private"],
    )

    cc_library(
        name = name,
        srcs = [":" + srcs_target],
        hdrs = [":" + srcs_target],
        includes = includes,
        deps = [Label("//:zcm-coretypes")] + deps,
        visibility = visibility,
        **kwargs
    )
