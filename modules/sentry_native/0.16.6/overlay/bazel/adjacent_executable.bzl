"""Test helper for executable-relative runtime dependencies."""

def _adjacent_executable_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = output,
        target_file = ctx.executable.src,
        is_executable = True,
    )
    return DefaultInfo(
        executable = output,
        files = depset([output]),
    )

adjacent_executable = rule(
    implementation = _adjacent_executable_impl,
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            cfg = "target",
            executable = True,
            mandatory = True,
        ),
    },
    executable = True,
)
