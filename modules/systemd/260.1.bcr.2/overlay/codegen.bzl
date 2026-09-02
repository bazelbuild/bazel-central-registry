"""Code-generation rules for systemd.

`cc_macro_list` runs a small bash script through the configured C compiler
(cc_toolchain) to enumerate UAPI macros from a target header (e.g. AF_*,
ARPHRD_*, CAP_*, errno, STATX_*). The generator scripts are vendored
as-is from upstream systemd; they expect `$CC -E -dM -include <header>`
followed by extra include flags. We forward `-isystem` for the systemd
override + uapi dirs so that override headers (e.g. linux/capability.h)
take precedence over the sysroot's, matching upstream meson's behaviour.

The output is a plain text file with one identifier per line; downstream
genrules feed it to gperf or awk.
"""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

def _cc_macro_list_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    compiler = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = "c-compile",
    )

    out = ctx.outputs.out
    workspace_root = ctx.label.workspace_root
    prefix = (workspace_root + "/") if workspace_root else ""

    # Ask the C++ toolchain for the real compile command line instead of
    # reconstructing target/sysroot/include flags by hand. This keeps this
    # generator aligned with whatever C toolchain Bazel selected, including
    # cross toolchains that encode the target in features rather than in
    # cc_toolchain fields.
    #
    # `-E -x c` is still needed because some upstream generate-*-list.sh
    # scripts invoke `$CC -dM -include <header> - </dev/null` without `-E`,
    # relying on gcc's behaviour where `-dM` implies `-E`. clang is stricter.
    compile_variables = cc_common.create_compile_variables(
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        system_include_directories = depset(
            direct = [prefix + d for d in ctx.attr.system_includes],
        ),
        user_compile_flags = ["-E", "-x", "c"],
    )
    flags = list(cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.c_compile,
        variables = compile_variables,
    ))
    for d in ctx.attr.system_includes:
        flags += ["-isystem", prefix + d]

    ctx.actions.run_shell(
        outputs = [out],
        inputs = depset(
            direct = [ctx.file.script] + ctx.files.headers,
            transitive = [cc_toolchain.all_files],
        ),
        arguments = [out.path, ctx.file.script.path, compiler] + flags,
        command = 'out="$1"; shift; bash "$@" > "$out"',
        mnemonic = "GenMacroList",
        progress_message = "Generating %s" % out.short_path,
    )

    return [DefaultInfo(files = depset([out]))]

cc_macro_list = rule(
    implementation = _cc_macro_list_impl,
    attrs = {
        "script": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The generate-<name>-list.sh script.",
        ),
        "headers": attr.label_list(
            allow_files = True,
            doc = "Override headers that need to be visible to the cpp run.",
        ),
        "system_includes": attr.string_list(
            doc = "Paths passed as -isystem after the compiler.",
        ),
        "out": attr.output(
            mandatory = True,
            doc = "Path of the generated text file (relative to package).",
        ),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)
