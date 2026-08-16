"""Bazel rules for ZeroCM message generation."""

load("@rules_cc//cc:defs.bzl", "cc_library")

def _zcm_srcs_impl(ctx):
    types = ctx.attr.types or [s.basename[:-4] for s in ctx.files.srcs]
    pkg_parts = [ctx.bin_dir.path, ctx.label.workspace_root, ctx.label.package] if ctx.attr.unpackaged else [ctx.bin_dir.path, ctx.label.workspace_root]
    hpath = "/".join([p for p in pkg_parts if p])

    args = ctx.actions.args()
    if ctx.attr.lang == "c":
        outs = [ctx.actions.declare_file(t + ext) for t in types for ext in [".h", ".c"]]
        args.add("--c")
        args.add("--c-hpath", hpath)
        args.add("--c-cpath", hpath)
        mnemonic = "ZcmGenC"
    else:
        outs = [ctx.actions.declare_file(t + ".hpp") for t in types]
        args.add("--cpp")
        args.add("--cpp-hpath", hpath)
        mnemonic = "ZcmGenCpp"
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        inputs = ctx.files.srcs,
        outputs = outs,
        executable = ctx.executable._zcm_gen,
        arguments = [args],
        mnemonic = mnemonic,
        progress_message = "Generating ZCM %s sources for %s" % (ctx.attr.lang.upper(), ctx.label),
    )
    return [DefaultInfo(files = depset(outs))]

_zcm_srcs = rule(
    implementation = _zcm_srcs_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".zcm"], mandatory = True),
        "types": attr.string_list(),
        "lang": attr.string(values = ["c", "cpp"], mandatory = True),
        "unpackaged": attr.bool(default = False),
        "_zcm_gen": attr.label(default = Label("//:zcm-gen"), executable = True, cfg = "exec"),
    },
)

def _zcm_library(name, lang, default_dep, srcs = [], types = [], unpackaged = False, deps = [], **kwargs):
    srcs_target = "%s_gen_srcs" % name
    _zcm_srcs(
        name = srcs_target,
        srcs = srcs,
        types = types,
        lang = lang,
        unpackaged = unpackaged,
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = name,
        srcs = [":" + srcs_target] if lang == "c" else [],
        hdrs = [":" + srcs_target],
        deps = [default_dep] + deps,
        **kwargs
    )

def zcm_c_library(name, **kwargs):
    """Convenience macro generating a cc_library with generated ZCM C sources and headers."""
    _zcm_library(name = name, lang = "c", default_dep = Label("//:zcm-core"), **kwargs)

def zcm_cc_library(name, **kwargs):
    """Convenience macro generating a cc_library with generated ZCM C++ headers."""
    _zcm_library(name = name, lang = "cpp", default_dep = Label("//:zcm-coretypes"), **kwargs)
