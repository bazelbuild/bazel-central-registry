load("@rules_cc//cc:cc_library.bzl", "cc_library")

def _sanitize(src):
    return src.replace("/", "_").replace(".", "_").replace("-", "_")

def _parent_prefix(src):
    depth = len(src.split("/")) - 1
    return "../" * depth

def _copy_text_file_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file.src,
        output = ctx.outputs.out,
        substitutions = {},
    )

    return [DefaultInfo(files = depset([ctx.outputs.out]))]

_copy_text_file = rule(
    implementation = _copy_text_file_impl,
    attrs = {
        "out": attr.output(mandatory = True),
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
    },
)

def _libvpx_arm_asm_source_impl(ctx):
    perl_toolchain = ctx.attr._current_perl_toolchain[platform_common.ToolchainInfo]
    perl = perl_toolchain.perl_runtime.interpreter
    args = ctx.actions.args()
    args.add("-e")
    args.add("""use strict; use warnings;
my ($out, $script, $src, $config_include, @script_args) = @ARGV;
open my $in, '<', $src or die "open($src): $!";
open STDOUT, '>', $out or die "open($out): $!";
local *STDIN = $in;
local @ARGV = @script_args;
my $script_to_run = $script;
$script_to_run = "./" . $script_to_run unless $script_to_run =~ m{^(?:/|[A-Za-z]:[\\/])};
my $rv = do $script_to_run;
die $@ if $@;
die "do($script_to_run) failed: $!" unless defined $rv;
close STDOUT or die "close($out): $!";
open my $read, '<', $out or die "open($out): $!";
local $/;
my $content = <$read>;
close $read or die "close($out): $!";
$content =~ s#\\.include "\\./vpx_config\\.asm"#.include "$config_include"."vpx_config.asm"#g;
open my $write, '>', $out or die "open($out): $!";
print {$write} $content or die "write($out): $!";
close $write or die "close($out): $!";
""")
    args.add(ctx.outputs.out.path)
    args.add(ctx.file.script.path)
    args.add(ctx.file.src.path)
    args.add(ctx.attr.config_include)
    args.add_all(ctx.attr.script_args)

    ctx.actions.run(
        executable = perl,
        inputs = [
            ctx.file.authors,
            ctx.file.config_target,
            ctx.file.script,
            ctx.file.src,
            ctx.file.thumb_pm,
        ],
        outputs = [ctx.outputs.out],
        tools = depset(
            direct = [perl],
            transitive = [perl_toolchain.perl_runtime.runtime],
        ),
        arguments = [args],
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
    },
)

def libvpx_arm_asm_library(name, srcs, config_target, target_compatible_with = None):
    if target_compatible_with == None:
        target_compatible_with = []

    config_name = "{}_config".format(name)
    config_out = "arm_asm/{}/vpx_config.asm".format(name)
    _copy_text_file(
        name = config_name,
        src = config_target,
        out = config_out,
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
