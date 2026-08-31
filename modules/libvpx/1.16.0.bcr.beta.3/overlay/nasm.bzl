load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

def _sanitize(src):
    return src.replace("/", "_").replace(".", "_").replace("-", "_")

def _parent_prefix(src):
    depth = len(src.split("/")) - 1
    return "../" * depth

def _libvpx_arm_asm_source_impl(ctx):
    perl_toolchain = ctx.attr._current_perl_toolchain[platform_common.ToolchainInfo]
    perl = perl_toolchain.perl_runtime.interpreter
    args = ctx.actions.args()
    args.add(ctx.outputs.out)
    args.add(ctx.file.script)
    args.add(ctx.file.src)
    args.add(ctx.attr.config_include)
    args.add_all(ctx.attr.script_args)

    ctx.actions.run(
        executable = perl,
        inputs = [
            ctx.file.authors,
            ctx.file.config_target,
            ctx.file._perl_wrapper,
            ctx.file.script,
            ctx.file.src,
            ctx.file.thumb_pm,
        ],
        outputs = [ctx.outputs.out],
        tools = depset(
            direct = [perl],
            transitive = [perl_toolchain.perl_runtime.runtime],
        ),
        arguments = [ctx.file._perl_wrapper.path, args],
        mnemonic = "LibvpxArmAsmSource",
    )

    return [DefaultInfo(files = depset([ctx.outputs.out]))]

_libvpx_arm_asm_source = rule(
    implementation = _libvpx_arm_asm_source_impl,
    attrs = {
        "authors": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "config_include": attr.string(mandatory = True),
        "config_target": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "out": attr.output(mandatory = True),
        "script": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "script_args": attr.string_list(),
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "thumb_pm": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "_current_perl_toolchain": attr.label(
            cfg = "exec",
            default = Label("@rules_perl//:current_toolchain"),
        ),
        "_perl_wrapper": attr.label(
            allow_single_file = True,
            default = Label("@libvpx//:ads2gas_do_wrapper.pl"),
        ),
    },
)

def libvpx_arm_asm_library(name, srcs, config_target, target_compatible_with = None):
    if target_compatible_with == None:
        target_compatible_with = []

    config_name = "{}_config".format(name)
    config_out = "arm_asm/{}/vpx_config.asm".format(name)
    expand_template(
        name = config_name,
        substitutions = {},
        out = config_out,
        template = config_target,
        target_compatible_with = target_compatible_with,
    )

    converted_srcs = []
    for src in srcs:
        rule_name = "{}_{}".format(name, _sanitize(src))
        out_name = "arm_asm/{}/{}.S".format(name, src)
        converted_srcs.append(out_name)
        _libvpx_arm_asm_source(
            name = rule_name,
            authors = "AUTHORS",
            config_include = _parent_prefix(src),
            config_target = config_target,
            out = out_name,
            script = "build/make/ads2gas.pl",
            script_args = [],
            src = src,
            thumb_pm = "build/make/thumb.pm",
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
