def _libvpx_rtcd_header_impl(ctx):
    perl_toolchain = ctx.attr._current_perl_toolchain[platform_common.ToolchainInfo]
    perl = perl_toolchain.perl_runtime.interpreter
    args = ctx.actions.args()
    args.add(ctx.outputs.out)
    args.add(ctx.file.rtcd_script)
    args.add(ctx.attr.arch, format = "--arch=%s")
    args.add(ctx.attr.sym, format = "--sym=%s")
    args.add_all(ctx.attr.extra_args)
    args.add(ctx.file.config_file, format = "--config=%s")
    args.add(ctx.file.defs_file)

    ctx.actions.run(
        executable = perl,
        inputs = [
            ctx.file.config_file,
            ctx.file.defs_file,
            ctx.file._perl_wrapper,
            ctx.file.rtcd_script,
        ],
        outputs = [ctx.outputs.out],
        tools = depset(
            direct = [perl],
            transitive = [perl_toolchain.perl_runtime.runtime],
        ),
        arguments = [ctx.file._perl_wrapper.path, args],
        mnemonic = "LibvpxRtcdHeader",
    )

    return [DefaultInfo(files = depset([ctx.outputs.out]))]

_libvpx_rtcd_header = rule(
    implementation = _libvpx_rtcd_header_impl,
    attrs = {
        "arch": attr.string(mandatory = True),
        "config_file": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "defs_file": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "extra_args": attr.string_list(),
        "out": attr.output(mandatory = True),
        "rtcd_script": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "sym": attr.string(mandatory = True),
        "_current_perl_toolchain": attr.label(
            cfg = "exec",
            default = Label("@rules_perl//:current_toolchain"),
        ),
        "_perl_wrapper": attr.label(
            allow_single_file = True,
            default = Label("@libvpx//:rtcd_do_wrapper.pl"),
        ),
    },
)

def libvpx_rtcd_headers(name, arch, config_file, out_dir, disable_avx512 = False, disable_neon_i8mm = False, disable_sve = False, disable_sve2 = False):
    extra_args = []
    if disable_avx512:
        extra_args.append("--disable-avx512")
    if disable_neon_i8mm:
        extra_args.append("--disable-neon_i8mm")
    if disable_sve:
        extra_args.append("--disable-sve")
    if disable_sve2:
        extra_args.append("--disable-sve2")

    defs = [
        ("vp8_rtcd", "@libvpx//:vp8/common/rtcd_defs.pl"),
        ("vp9_rtcd", "@libvpx//:vp9/common/vp9_rtcd_defs.pl"),
        ("vpx_dsp_rtcd", "@libvpx//:vpx_dsp/vpx_dsp_rtcd_defs.pl"),
        ("vpx_scale_rtcd", "@libvpx//:vpx_scale/vpx_scale_rtcd.pl"),
    ]

    generated = []
    for sym, defs_file in defs:
        out = "{}/{}.h".format(out_dir, sym)
        target_name = "{}_{}".format(name, sym)
        _libvpx_rtcd_header(
            name = target_name,
            arch = arch,
            config_file = config_file,
            defs_file = defs_file,
            extra_args = extra_args,
            out = out,
            rtcd_script = "@libvpx//:build/make/rtcd.pl",
            sym = sym,
        )
        generated.append(target_name)

    native.filegroup(
        name = name,
        srcs = generated,
    )
