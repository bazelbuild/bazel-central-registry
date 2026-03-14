def libvpx_rtcd_headers(name, arch, config_header, out_dir, disable_avx512 = False, disable_neon_i8mm = False, disable_sve = False, disable_sve2 = False):
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
    native.genrule(
        name = name,
        srcs = [
            config_header,
            "@libvpx//:vp8/common/rtcd_defs.pl",
            "@libvpx//:vp9/common/vp9_rtcd_defs.pl",
            "@libvpx//:vpx_dsp/vpx_dsp_rtcd_defs.pl",
            "@libvpx//:vpx_scale/vpx_scale_rtcd.pl",
        ],
        outs = [
            "{}/vp8_rtcd.h".format(out_dir),
            "{}/vp9_rtcd.h".format(out_dir),
            "{}/vpx_dsp_rtcd.h".format(out_dir),
            "{}/vpx_scale_rtcd.h".format(out_dir),
        ],
        cmd = """
set -eu
CONFIG_FILE="$(@D)/{name}.config"
mkdir -p "$(RULEDIR)/{out_dir}"
awk '/^#define (CONFIG_|HAVE_)/ {{ value=$$3; if (value == 1) value = "yes"; else if (value == 0) value = "no"; print $$2 "=" value; }}' $(location {config_header}) > "$$CONFIG_FILE"
/usr/bin/perl $(location @libvpx//:build/make/rtcd.pl) --arch={arch} --sym=vp8_rtcd {extra_arg} --config="$$CONFIG_FILE" $(location @libvpx//:vp8/common/rtcd_defs.pl) > "$(RULEDIR)/{out_dir}/vp8_rtcd.h"
/usr/bin/perl $(location @libvpx//:build/make/rtcd.pl) --arch={arch} --sym=vp9_rtcd {extra_arg} --config="$$CONFIG_FILE" $(location @libvpx//:vp9/common/vp9_rtcd_defs.pl) > "$(RULEDIR)/{out_dir}/vp9_rtcd.h"
/usr/bin/perl $(location @libvpx//:build/make/rtcd.pl) --arch={arch} --sym=vpx_dsp_rtcd {extra_arg} --config="$$CONFIG_FILE" $(location @libvpx//:vpx_dsp/vpx_dsp_rtcd_defs.pl) > "$(RULEDIR)/{out_dir}/vpx_dsp_rtcd.h"
/usr/bin/perl $(location @libvpx//:build/make/rtcd.pl) --arch={arch} --sym=vpx_scale_rtcd {extra_arg} --config="$$CONFIG_FILE" $(location @libvpx//:vpx_scale/vpx_scale_rtcd.pl) > "$(RULEDIR)/{out_dir}/vpx_scale_rtcd.h"
""".format(
            arch = arch,
            config_header = config_header,
            extra_arg = extra_arg,
            name = name,
            out_dir = out_dir,
        ),
        tools = ["@libvpx//:build/make/rtcd.pl"],
    )
