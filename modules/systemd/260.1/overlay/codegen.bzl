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

    # `-E -x c` is needed because some upstream generate-*-list.sh scripts
    # invoke `$CC -dM -include <header> - </dev/null` without `-E`, relying
    # on gcc's behaviour where `-dM` implies `-E`. clang is stricter.
    flags = ["-E", "-x", "c"]
    # gcc cross-compiles via a target-specific binary (aarch64-linux-gnu-gcc
    # etc.) and rejects --target=; clang takes a single binary and routes
    # through --target=. So we sniff.
    if "clang" in cc_toolchain.compiler:
        flags.append("--target=" + cc_toolchain.target_gnu_system_name)
    if cc_toolchain.sysroot:
        flags.append("--sysroot=" + cc_toolchain.sysroot)
    for d in cc_toolchain.built_in_include_directories:
        flags += ["-isystem", d]
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
