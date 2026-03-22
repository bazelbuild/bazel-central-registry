load("@rules_cc//cc:cc_library.bzl", "cc_library")

def _sanitize(src):
    return src.replace("/", "_").replace(".", "_").replace("-", "_")

def _parent_prefix(src):
    depth = len(src.split("/")) - 1
    return "../" * depth

def libvpx_arm_asm_library(name, srcs, config_target, target_compatible_with = None):
    if target_compatible_with == None:
        target_compatible_with = []

    config_name = "{}_config".format(name)
    config_out = "arm_asm/{}/vpx_config.asm".format(name)
    native.genrule(
        name = config_name,
        srcs = [config_target],
        outs = [config_out],
        cmd = """
set -eu
mkdir -p "$$(dirname $@)"
cp $(location {config_target}) $@
""".format(config_target = config_target),
        target_compatible_with = target_compatible_with,
    )

    converted_srcs = []
    for src in srcs:
        rule_name = "{}_{}".format(name, _sanitize(src))
        out_name = "arm_asm/{}/{}.S".format(name, src)
        converted_srcs.append(out_name)
        native.genrule(
            name = rule_name,
            srcs = [
                "AUTHORS",
                src,
                "build/make/ads2gas.pl",
                "build/make/thumb.pm",
                config_target,
            ],
            outs = [out_name],
            cmd = """
set -eu
mkdir -p "$$(dirname $@)"
"$(PERL)" $(location build/make/ads2gas.pl) < $(location {src}) > $@
"$(PERL)" -0pi -e 's#\\.include "\\./vpx_config\\.asm"#.include "{config_include}vpx_config.asm"#g' $@
""".format(
                src = src,
                config_include = _parent_prefix(src),
            ),
            target_compatible_with = target_compatible_with,
            toolchains = ["@rules_perl//perl:current_exec_toolchain"],
        )

    cc_library(
        name = name,
        srcs = converted_srcs,
        hdrs = [config_out],
        copts = [
            "-Wa,-I$(GENDIR)/arm_asm/{}".format(name),
            "-Wa,-I$(GENDIR)/external/libvpx/arm_asm/{}".format(name),
            "-mfpu=neon",
        ],
        target_compatible_with = target_compatible_with,
        visibility = ["//visibility:private"],
    )
