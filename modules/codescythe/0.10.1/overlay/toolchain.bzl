"""Codescythe binary toolchain."""

def _codescythe_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        codescythe = ctx.executable.codescythe,
    )]

codescythe_toolchain = rule(
    implementation = _codescythe_toolchain_impl,
    attrs = {
        "codescythe": attr.label(
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
    },
)

def _codescythe_binary_impl(ctx):
    codescythe = ctx.toolchains["//:toolchain_type"].codescythe
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = executable,
        target_file = codescythe,
        is_executable = True,
    )
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = [codescythe]),
    )]

codescythe_binary = rule(
    implementation = _codescythe_binary_impl,
    executable = True,
    toolchains = ["//:toolchain_type"],
)
