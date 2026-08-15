"""Bazel rules for ZeroCM message generation."""

load("@rules_cc//cc:defs.bzl", "cc_library")

def _zcm_library_impl(ctx):
    return [
        DefaultInfo(files = depset(ctx.files.srcs)),
    ]

zcm_library = rule(
    implementation = _zcm_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".zcm"], mandatory = True),
        "zcm_package": attr.string(mandatory = False),
    },
)

def _zcm_cc_library_srcs_impl(ctx):
    out_hdrs = []
    for src in ctx.files.src:
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
    args.add_all(ctx.files.src)

    ctx.actions.run(
        inputs = ctx.files.src,
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
        "src": attr.label(mandatory = True),
        "_zcm_gen": attr.label(
            default = Label("//:zcm-gen"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def zcm_cc_library(name, srcs = None, src = None, visibility = None, **kwargs):
    """Convenience macro generating a cc_library with generated ZCM C++ headers."""
    if srcs != None and src == None:
        lib_name = "%s_zcm_lib" % name
        zcm_library(
            name = lib_name,
            srcs = srcs,
            visibility = ["//visibility:private"],
        )
        src_target = ":" + lib_name
    else:
        src_target = src

    srcs_target = "%s_gen_srcs" % name
    zcm_cc_library_srcs(
        name = srcs_target,
        src = src_target,
        visibility = ["//visibility:private"],
    )

    cc_library(
        name = name,
        srcs = [":" + srcs_target],
        hdrs = [":" + srcs_target],
        includes = ["."],
        deps = [
            Label("//:zcm-coretypes"),
        ],
        visibility = visibility,
        **kwargs
    )
