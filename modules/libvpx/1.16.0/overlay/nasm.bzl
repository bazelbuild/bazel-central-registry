load("@rules_cc//cc:cc_library.bzl", "cc_library")

def _sanitize(src):
    return src.replace("/", "_").replace(".", "_").replace("-", "_")

def _parent_prefix(src):
    depth = len(src.split("/")) - 1
    return "../" * depth

def libvpx_x86_asm_library(name, srcs, config_target, target_compatible_with = None):
    if target_compatible_with == None:
        target_compatible_with = []

    common_inputs = [
        "AUTHORS",
    ] + native.glob([
        "third_party/x86inc/*.asm",
        "vp8/common/x86/*.asm",
        "vp8/encoder/x86/*.asm",
        "vp9/common/x86/*.asm",
        "vp9/encoder/x86/*.asm",
        "vpx_dsp/x86/*.asm",
        "vpx_ports/*.asm",
    ])

    obj_targets = []
    for src in srcs:
        rule_name = "{}_{}".format(name, _sanitize(src))
        out_name = "asm_objs/{}_{}.o".format(name, _sanitize(src))
        obj_targets.append(":{}".format(rule_name))
        native.genrule(
            name = rule_name,
            srcs = common_inputs + [config_target],
            outs = [out_name],
            cmd = select({
                ":linux_x86_64": """
set -eu
ROOT=$$(dirname $(location AUTHORS))
CONFIG_DIR=$$(dirname $(location {config_target}))
$(location @nasm//:nasm) -f elf64 -DELF -DPIC -D__x86_64__ \
  -I$$ROOT/ \
  -I$$CONFIG_DIR/ \
  -o $@ $(location {src})
""".format(config_target = config_target, src = src),
                ":android_x86_64": """
set -eu
ROOT=$$(dirname $(location AUTHORS))
CONFIG_DIR=$$(dirname $(location {config_target}))
$(location @nasm//:nasm) -f elf64 -DELF -DPIC -D__ANDROID__ -D__x86_64__ \
  -I$$ROOT/ \
  -I$$CONFIG_DIR/ \
  -o $@ $(location {src})
""".format(config_target = config_target, src = src),
                ":macos_x86_64": """
set -eu
ROOT=$$(dirname $(location AUTHORS))
CONFIG_DIR=$$(dirname $(location {config_target}))
$(location @nasm//:nasm) -f macho64 -D__x86_64__ \
  -I$$ROOT/ \
  -I$$CONFIG_DIR/ \
  -o $@ $(location {src})
""".format(config_target = config_target, src = src),
                ":ios_x86_64": """
set -eu
ROOT=$$(dirname $(location AUTHORS))
CONFIG_DIR=$$(dirname $(location {config_target}))
$(location @nasm//:nasm) -f macho64 -D__x86_64__ \
  -I$$ROOT/ \
  -I$$CONFIG_DIR/ \
  -o $@ $(location {src})
""".format(config_target = config_target, src = src),
                ":linux_x86": """
set -eu
ROOT=$$(dirname $(location AUTHORS))
CONFIG_DIR=$$(dirname $(location {config_target}))
$(location @nasm//:nasm) -f elf32 -DELF -DPIC \
  -I$$ROOT/ \
  -I$$CONFIG_DIR/ \
  -o $@ $(location {src})
""".format(config_target = config_target, src = src),
                ":android_x86": """
set -eu
ROOT=$$(dirname $(location AUTHORS))
CONFIG_DIR=$$(dirname $(location {config_target}))
$(location @nasm//:nasm) -f elf32 -DELF -DPIC -D__ANDROID__ \
  -I$$ROOT/ \
  -I$$CONFIG_DIR/ \
  -o $@ $(location {src})
""".format(config_target = config_target, src = src),
                "//conditions:default": "echo unsupported > /dev/null",
            }),
            tools = ["@nasm//:nasm"],
            target_compatible_with = target_compatible_with,
        )

    cc_library(
        name = name,
        srcs = obj_targets,
        target_compatible_with = target_compatible_with,
        visibility = ["//visibility:private"],
    )

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
/usr/bin/perl $(location build/make/ads2gas.pl) < $(location {src}) > $@
/usr/bin/perl -0pi -e 's#\\.include "\\./vpx_config\\.asm"#.include "{config_include}vpx_config.asm"#g' $@
""".format(
                src = src,
                config_include = _parent_prefix(src),
            ),
            target_compatible_with = target_compatible_with,
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
