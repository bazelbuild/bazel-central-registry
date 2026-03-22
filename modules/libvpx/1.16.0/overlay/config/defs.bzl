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
    extra_arg = " ".join(extra_args)

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
        native.genrule(
            name = target_name,
            srcs = [
                config_file,
                "@libvpx//:build/make/rtcd.pl",
                defs_file,
            ],
            outs = [out],
            cmd = """mkdir -p "$(@D)" && "$(PERL)" "$(execpath @libvpx//:build/make/rtcd.pl)" --arch={arch} --sym={sym} {extra_arg} --config="$(location {config_file})" "$(location {defs_file})" > "$@" """.format(
                arch = arch,
                config_file = config_file,
                defs_file = defs_file,
                extra_arg = extra_arg,
                sym = sym,
            ),
            cmd_bat = """(if not exist "$(@D)" mkdir "$(@D)") && "$(PERL)" "$(execpath @libvpx//:build/make/rtcd.pl)" --arch={arch} --sym={sym} {extra_arg} --config="$(location {config_file})" "$(location {defs_file})" > "$@" """.format(
                arch = arch,
                config_file = config_file,
                defs_file = defs_file,
                extra_arg = extra_arg,
                sym = sym,
            ),
            toolchains = ["@rules_perl//perl:current_exec_toolchain"],
        )
        generated.append(target_name)

    native.filegroup(
        name = name,
        srcs = generated,
    )
