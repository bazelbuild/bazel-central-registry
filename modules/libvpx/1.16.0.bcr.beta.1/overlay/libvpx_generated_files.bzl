def _libvpx_rtcd_header_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)

    perl_toolchain = ctx.attr._current_perl_toolchain[platform_common.ToolchainInfo]
    perl = perl_toolchain.perl_runtime.interpreter
    args = ctx.actions.args()
    args.add(out.path)
    args.add(perl.path)
    args.add(ctx.file.rtcd_script.path)
    args.add("--arch=generic")
    args.add("--sym=" + ctx.attr.sym)
    args.add("--config=" + ctx.file.config_mk.path)
    args.add(ctx.file.defs.path)

    ctx.actions.run_shell(
        tools = perl_toolchain.perl_runtime.runtime,
        inputs = [
            ctx.file.config_mk,
            ctx.file.rtcd_script,
            ctx.file.defs,
        ],
        outputs = [out],
        command = """
out="$1"
shift
"$@" > "$out"
""",
        arguments = [args],
        mnemonic = "LibvpxRtcdHeader",
    )

    return [DefaultInfo(files = depset([out]))]

libvpx_rtcd_header = rule(
    implementation = _libvpx_rtcd_header_impl,
    attrs = {
        "config_mk": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "defs": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "out": attr.string(mandatory = True),
        "rtcd_script": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "sym": attr.string(mandatory = True),
        "_current_perl_toolchain": attr.label(
            cfg = "exec",
            default = Label("@rules_perl//:current_toolchain"),
        ),
    },
)

def libvpx_rtcd_headers(name, config_mk, rtcd_script):
    private_visibility = ["//visibility:private"]
    generated_headers = [
        ("vp8", "vp8/common/rtcd_defs.pl", "generated/vp8_rtcd.h", "vp8_rtcd"),
        ("vp9", "vp9/common/vp9_rtcd_defs.pl", "generated/vp9_rtcd.h", "vp9_rtcd"),
        ("vpx_dsp", "vpx_dsp/vpx_dsp_rtcd_defs.pl", "generated/vpx_dsp_rtcd.h", "vpx_dsp_rtcd"),
        ("vpx_scale", "vpx_scale/vpx_scale_rtcd.pl", "generated/vpx_scale_rtcd.h", "vpx_scale_rtcd"),
    ]
    srcs = []

    for suffix, defs, out, sym in generated_headers:
        target_name = name + "_" + suffix
        libvpx_rtcd_header(
            name = target_name,
            config_mk = config_mk,
            defs = defs,
            out = out,
            rtcd_script = rtcd_script,
            sym = sym,
            visibility = private_visibility,
        )
        srcs.append(":" + target_name)

    native.filegroup(
        name = name,
        srcs = srcs,
        visibility = private_visibility,
    )
