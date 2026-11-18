"""Generate the CPU JIT preamble with the resolved C/C++ toolchain."""

load("@bazel_skylib//lib:shell.bzl", "shell")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "CC_TOOLCHAIN_TYPE", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

def _cpu_compiled_preamble_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    # Match mlx/backend/cpu/CMakeLists.txt: macOS preprocesses as C with
    # standard headers omitted; other platforms preprocess as C++.
    is_macos = ctx.target_platform_has_constraint(ctx.attr._macos[platform_common.ConstraintValueInfo])
    action_name = ACTION_NAMES.c_compile if is_macos else ACTION_NAMES.cpp_compile
    compiler = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = action_name,
    )
    compile_variables = cc_common.create_compile_variables(
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        user_compile_flags = ctx.fragments.cpp.copts + (
            ctx.fragments.cpp.conlyopts if is_macos else ctx.fragments.cpp.cxxopts + ["-x", "c++"]
        ),
    )
    flags = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = action_name,
        variables = compile_variables,
    )

    # Upstream accepts a compiler path, not a compiler plus arguments. A
    # wrapper preserves argument boundaries for toolchain target/sysroot flags.
    wrapper = ctx.actions.declare_file(ctx.label.name + "_compiler.sh")
    ctx.actions.write(
        output = wrapper,
        content = "#!/bin/bash\nexec {} \"$@\"\n".format(" ".join([shell.quote(arg) for arg in [compiler] + flags])),
        is_executable = True,
    )
    source_root = ctx.label.workspace_root or "."
    ctx.actions.run_shell(
        outputs = [ctx.outputs.out],
        inputs = depset(
            [ctx.file.script, wrapper] + ctx.files.hdrs,
            transitive = [cc_toolchain.all_files],
        ),
        arguments = [
            ctx.file.script.path,
            ctx.outputs.out.path,
            wrapper.path,
            source_root,
            "TRUE" if is_macos else "FALSE",
            ctx.attr.arch,
        ],
        command = """
bash "$1" "$2" "$3" "$4" "$5" "$6" ""
# Upstream hides compiler errors and can succeed with an empty preamble.
grep -q 'struct Abs' "$2" || { echo "Failed to preprocess the CPU compiled preamble" >&2; exit 1; }
""",
        env = cc_common.get_environment_variables(
            feature_configuration = feature_configuration,
            action_name = action_name,
            variables = compile_variables,
        ),
        execution_requirements = {
            requirement: ""
            for requirement in cc_common.get_execution_requirements(
                feature_configuration = feature_configuration,
                action_name = action_name,
            )
        },
        mnemonic = "CpuCompiledPreamble",
        progress_message = "Generating MLX CPU compiled preamble",
        toolchain = CC_TOOLCHAIN_TYPE,
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

cpu_compiled_preamble = rule(
    implementation = _cpu_compiled_preamble_impl,
    attrs = {
        "arch": attr.string(),
        "hdrs": attr.label_list(allow_files = [".h"]),
        "out": attr.output(mandatory = True),
        "script": attr.label(allow_single_file = [".sh"], mandatory = True),
        "_macos": attr.label(default = "@platforms//os:macos"),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)
