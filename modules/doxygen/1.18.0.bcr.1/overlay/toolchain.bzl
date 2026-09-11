"""Doxygen toolchain definitions."""

DoxygenToolchainInfo = provider(
    doc = "The executable used to run Doxygen.",
    fields = {"executable": "Doxygen's FilesToRunProvider."},
)

def _doxygen_executable_impl(ctx):
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = executable,
        target_file = ctx.file.src,
        is_executable = True,
    )
    return [DefaultInfo(executable = executable)]

doxygen_executable = rule(
    implementation = _doxygen_executable_impl,
    executable = True,
    attrs = {"src": attr.label(allow_single_file = True, mandatory = True)},
    doc = "Exposes a built Doxygen binary as an executable target.",
)

def _doxygen_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        doxygen = DoxygenToolchainInfo(
            executable = ctx.attr.executable[DefaultInfo].files_to_run,
        ),
    )]

doxygen_toolchain = rule(
    implementation = _doxygen_toolchain_impl,
    attrs = {
        "executable": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
            doc = "The Doxygen executable.",
        ),
    },
    doc = "Defines a Doxygen toolchain implementation.",
)
