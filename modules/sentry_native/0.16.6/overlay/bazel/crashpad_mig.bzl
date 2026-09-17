"""Cross-platform Crashpad MIG source generation."""

load("@rules_cc//cc:action_names.bzl", "C_COMPILE_ACTION_NAME")
load("@rules_cc//cc:find_cc_toolchain.bzl", "CC_TOOLCHAIN_ATTRS", "find_cpp_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

_PYTHON_EXEC_TOOLS_TOOLCHAIN_TYPE = "@rules_python//python:exec_tools_toolchain_type"

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
    fail("Crashpad MIG requires a C++ toolchain with a declared macOS sysroot")

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
    clang = cc_common.get_tool_for_action(
        action_name = C_COMPILE_ACTION_NAME,
        feature_configuration = feature_configuration,
    )
    python_exec_tools = ctx.toolchains[_PYTHON_EXEC_TOOLS_TOOLCHAIN_TYPE].exec_tools
    if not python_exec_tools.exec_interpreter:
        fail("Crashpad MIG requires a hermetic Python execution interpreter")
    python_runtime = python_exec_tools.exec_interpreter[platform_common.ToolchainInfo].py3_runtime
    if not python_runtime.interpreter:
        fail("Crashpad MIG requires a file-backed hermetic Python execution interpreter")
    python = python_runtime.interpreter

    sources = []
    headers = []
    crashpad_dir = ctx.file.child_port_defs.dirname + "/../.."
    compat_dir = crashpad_dir + "/compat/mac"
    output_dir = "{}/util/mach".format(ctx.attr.output_dir)

    action_inputs = depset(
        direct = [
            ctx.file.child_port_defs,
            ctx.file.child_port_types,
            ctx.file.mig_driver,
        ] + ctx.files.compat_headers + ctx.files.mig_driver_support,
        transitive = [
            cc_toolchain.all_files,
            python_runtime.files,
        ],
    )
    action_tools = [
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
        args.add("-B")
        args.add(ctx.file.mig_driver)
        args.add("--arch={}".format(ctx.attr.arch))
        args.add("--sdk={}".format(sysroot))
        args.add("--include={}".format(crashpad_dir))
        args.add("--include={}".format(compat_dir))
        args.add("--clang-path={}".format(clang))
        args.add("--mig-path={}".format(ctx.executable.mig.path))
        args.add("--migcom-path={}".format(ctx.executable.migcom.path))
        args.add(defs)
        args.add_all(outputs)

        ctx.actions.run(
            arguments = [args],
            executable = python,
            inputs = action_inputs,
            mnemonic = "CrashpadMig",
            outputs = outputs,
            progress_message = "Generating {} Crashpad MIG interface for %{{label}}".format(interface),
            tools = action_tools,
        )

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
            allow_single_file = [".py"],
            mandatory = True,
        ),
        "mig_driver_support": attr.label_list(allow_files = [".py"]),
        "migcom": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "output_dir": attr.string(default = "mig"),
    } | CC_TOOLCHAIN_ATTRS,
    fragments = ["cpp"],
    toolchains = use_cc_toolchain() + [_PYTHON_EXEC_TOOLS_TOOLCHAIN_TYPE],
)
