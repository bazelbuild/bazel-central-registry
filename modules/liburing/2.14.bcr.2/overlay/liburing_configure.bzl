# SPDX-License-Identifier: Apache-2.0
"""Runs liburing's ./configure with the flags Bazel's C compiler actually uses.

liburing decides which compatibility shims to emit by trying to compile small
programs.  Handing those probes an incomplete command line makes them fail for
reasons that have nothing to do with the feature being probed, and configure
reads that failure as "the platform doesn't have it" and emits a fallback
definition.  When the platform did have it, the fallback then collides with the
real one and the library stops compiling.

A genrule can't avoid this: it can only reach $(CC) and $(CC_FLAGS), and
$(CC_FLAGS) is missing the target architecture triple.  It does carry the
sysroot, so cross compiling the probes get a compiler defaulting to the host
architecture pointed at a sysroot for the target one, and every probe that
includes a libc header fails on the mismatch.  Reaching the full command line
means asking the toolchain for it through cc_common, which needs a rule.
"""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

visibility("private")

# Flags which make sense when compiling a translation unit but not when running
# a configure probe.  Dependency-file flags name an output configure has no
# reason to write, and configure supplies its own -o/-c.
_SKIPPED_FLAGS = [
    "-MD",
    "-MMD",
    "-MF",
    "-MT",
    "-MQ",
    "-o",
    "-c",
]

def _keep_flag(flag):
    # Probes are deliberately minimal and warn about things a real translation
    # unit wouldn't -- an unused variable is how several of them test for a
    # type.  Inheriting -Werror turns those warnings into a failed probe, and
    # configure reads a failed probe as "the platform lacks this" and emits a
    # fallback definition that then collides with the real one.
    if flag == "-Werror" or flag.startswith("-Werror="):
        return False
    for skipped in _SKIPPED_FLAGS:
        if flag == skipped or flag.startswith(skipped + "="):
            return False
    return True

def _output_relative_path(ctx, output):
    """Returns output's path relative to this package's output directory.

    That is where configure writes it, since the action runs from the execroot.
    """
    prefix_parts = [ctx.bin_dir.path]
    if ctx.label.workspace_root:
        prefix_parts.append(ctx.label.workspace_root)
    if ctx.label.package:
        prefix_parts.append(ctx.label.package)
    prefix = "/".join(prefix_parts) + "/"
    if not output.path.startswith(prefix):
        fail("Expected {} to be under {}".format(output.path, prefix))
    return output.path[len(prefix):]

def _liburing_configure_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    compiler = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.c_compile,
    )
    compile_variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
    )
    compiler_options = [
        flag
        for flag in cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.c_compile,
            variables = compile_variables,
        )
        if _keep_flag(flag)
    ]

    outputs = ctx.outputs.outs

    # configure writes its outputs relative to the working directory, and the
    # sysroot in the compile flags is relative to the execroot, so stay in the
    # execroot and fake an out-of-source build with symlinks the way liburing's
    # own packaging does.
    ctx.actions.run_shell(
        outputs = outputs,
        inputs = depset(
            ctx.files.srcs + [ctx.executable.configure],
            transitive = [cc_toolchain.all_files],
        ),
        tools = [ctx.executable.configure],
        command = """
set -e
export CC="$1"
export CFLAGS="$2"
export LDFLAGS="-c"
configure="$3"
shift 3

package_dir="$(dirname "${configure}")"
ln -sf "${package_dir}/Makefile.common" Makefile.common
ln -sf "${package_dir}/liburing.spec" liburing.spec
mkdir -p src/include/liburing
"${configure}" --use-libc

# configure wrote each header relative to the working directory; move it to
# where Bazel declared it.
for pair in "$@"; do
  cp "${pair%%=*}" "${pair#*=}"
done
""",
        arguments = [
            compiler,
            " ".join(compiler_options),
            ctx.executable.configure.path,
        ] + [
            "{}={}".format(_output_relative_path(ctx, output), output.path)
            for output in outputs
        ],
        # configure shells out to make, awk, sed and friends, so it needs a PATH
        # to find them.  Actions get a scrubbed environment by default, which
        # leaves make reporting "awk: No such file or directory"; the genrule
        # this replaced got the default environment implicitly.
        use_default_shell_env = True,
        mnemonic = "LiburingConfigure",
        progress_message = "Configuring liburing for %{label}",
    )

    return [DefaultInfo(files = depset(outputs))]

liburing_configure = rule(
    implementation = _liburing_configure_impl,
    attrs = {
        "configure": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            doc = "liburing's configure script.",
        ),
        "outs": attr.output_list(
            mandatory = True,
            doc = "Headers configure generates.  Declared as outputs so other " +
                  "targets can depend on them by label.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Files configure reads while probing.",
        ),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
    doc = "Generates liburing's configure-time headers for the target platform.",
)
