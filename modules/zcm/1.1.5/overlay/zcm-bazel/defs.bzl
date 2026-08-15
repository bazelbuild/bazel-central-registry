"""Bazel rules for ZeroCM message generation."""

load("@rules_cc//cc:defs.bzl", "cc_library")

def _zcm_cc_library_srcs_impl(ctx):
    out_hdrs = []
    for src in ctx.files.srcs:
        pkg_prefix = ctx.label.package + "/" if ctx.label.package else ""
        if src.short_path.startswith(pkg_prefix):
            rel_path = src.short_path[len(pkg_prefix):]
        else:
            rel_path = src.basename
        out_hdr = ctx.actions.declare_file(rel_path[:-4] + ".hpp")
        out_hdrs.append(out_hdr)

    args = ctx.actions.args()
    args.add("--cpp")
    args.add("--cpp-hpath", ctx.bin_dir.path)
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
        "_zcm_gen": attr.label(
            default = Label("//:zcm-gen"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def zcm_cc_library(name, srcs = [], deps = [], includes = ["."], visibility = None, **kwargs):
    """Convenience macro generating a cc_library with generated ZCM C++ headers."""
    srcs_target = "%s_gen_srcs" % name
    zcm_cc_library_srcs(
        name = srcs_target,
        srcs = srcs,
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
