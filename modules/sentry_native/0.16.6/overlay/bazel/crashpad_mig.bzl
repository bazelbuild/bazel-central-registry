"""Cross-platform Crashpad MIG source generation."""

load("@apple_support//lib:apple_support.bzl", "apple_support")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:action_names.bzl", "C_COMPILE_ACTION_NAME")
load("@rules_cc//cc:find_cc_toolchain.bzl", "CC_TOOLCHAIN_ATTRS", "find_cpp_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

_INTERFACES = [
    "child_port",
    "exc",
    "mach_exc",
    "notify",
]

def _sysroot_from_compile_action(ctx, cc_toolchain, feature_configuration):
    compile_variables = cc_common.create_compile_variables(
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        output_file = ctx.label.name + ".o",
        source_file = ctx.file.child_port_defs.path,
    )
    command_line = cc_common.get_memory_inefficient_command_line(
        action_name = C_COMPILE_ACTION_NAME,
        feature_configuration = feature_configuration,
        variables = compile_variables,
    )
    for index, argument in enumerate(command_line):
        if argument == "-isysroot" and index + 1 < len(command_line):
            return command_line[index + 1]
        if argument.startswith("-isysroot=") or argument.startswith("--sysroot="):
            return argument.split("=", 1)[1]
    return None

def _uses_xcode_sdk(sysroot):
    return (
        not sysroot or
        sysroot == apple_support.path_placeholders.sdkroot() or
        paths.is_absolute(sysroot)
    )

def _crashpad_mig_impl(ctx):
    if ctx.attr.arch not in ["arm64", "x86_64"]:
        fail("Crashpad MIG supports only arm64 and x86_64 macOS targets")

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    sysroot = _sysroot_from_compile_action(ctx, cc_toolchain, feature_configuration)
    uses_xcode_sdk = _uses_xcode_sdk(sysroot)
    if uses_xcode_sdk:
        sysroot = apple_support.path_placeholders.sdkroot()
    clang = cc_common.get_tool_for_action(
        action_name = C_COMPILE_ACTION_NAME,
        feature_configuration = feature_configuration,
    )
    apple_platform_info = None
    xcode_config = None
    if uses_xcode_sdk:
        apple_platform_info = apple_support.platform_info_from_rule_ctx(ctx)
        xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig]
    sources = []
    headers = []
    crashpad_dir = ctx.file.child_port_defs.dirname + "/../.."
    compat_dir = crashpad_dir + "/compat/mac"
    output_dir = "{}/util/mach".format(ctx.attr.output_dir)

    action_inputs = depset(
        direct = [
            ctx.file.child_port_defs,
            ctx.file.child_port_types,
        ] + ctx.files.compat_headers,
        transitive = [cc_toolchain.all_files],
    )
    action_tools = [
        ctx.attr.mig_driver[DefaultInfo].files_to_run,
        ctx.attr.mig[DefaultInfo].files_to_run,
        ctx.attr.migcom[DefaultInfo].files_to_run,
    ]

    for interface in _INTERFACES:
        outputs = [
            ctx.actions.declare_file("{}/{}User.c".format(output_dir, interface)),
            ctx.actions.declare_file("{}/{}Server.c".format(output_dir, interface)),
            ctx.actions.declare_file("{}/{}.h".format(output_dir, interface)),
            ctx.actions.declare_file("{}/{}Server.h".format(output_dir, interface)),
        ]
        sources.extend(outputs[:2])
        headers.extend(outputs[2:])

        defs = ctx.file.child_port_defs.path
        if interface != "child_port":
            defs = "{}/usr/include/mach/{}.defs".format(sysroot, interface)

        args = ctx.actions.args()
        args.add("--arch={}".format(ctx.attr.arch))
        args.add("--sdk={}".format(sysroot))
        args.add("--include={}".format(crashpad_dir))
        args.add("--include={}".format(compat_dir))
        args.add("--clang-path={}".format(clang))
        args.add("--mig-path={}".format(ctx.executable.mig.path))
        args.add("--migcom-path={}".format(ctx.executable.migcom.path))
        args.add(defs)
        args.add_all(outputs)

        action_kwargs = {
            "arguments": [args],
            "executable": ctx.executable.mig_driver,
            "inputs": action_inputs,
            "mnemonic": "CrashpadMig",
            "outputs": outputs,
            "progress_message": "Generating {} Crashpad MIG interface for %{{label}}".format(interface),
            "tools": action_tools,
        }
        if uses_xcode_sdk:
            apple_support.run(
                actions = ctx.actions,
                apple_platform_info = apple_platform_info,
                xcode_config = xcode_config,
                xcode_path_resolve_level = apple_support.xcode_path_resolve_level.args,
                **action_kwargs
            )
        else:
            ctx.actions.run(**action_kwargs)

    return [
        DefaultInfo(files = depset(sources + headers)),
        OutputGroupInfo(
            mig_headers = depset(headers),
            mig_sources = depset(sources),
        ),
    ]

crashpad_mig = rule(
    implementation = _crashpad_mig_impl,
    attrs = {
        "arch": attr.string(mandatory = True),
        "child_port_defs": attr.label(
            allow_single_file = [".defs"],
            mandatory = True,
        ),
        "child_port_types": attr.label(
            allow_single_file = [".h"],
            mandatory = True,
        ),
        "compat_headers": attr.label_list(allow_files = [".h"]),
        "mig": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "mig_driver": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "migcom": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "output_dir": attr.string(default = "mig"),
    } | CC_TOOLCHAIN_ATTRS | apple_support.action_required_attrs() | apple_support.platform_constraint_attrs(),
    fragments = ["apple", "cpp"],
    toolchains = use_cc_toolchain(),
)
