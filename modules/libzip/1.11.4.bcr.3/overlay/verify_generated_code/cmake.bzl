def _impl(ctx):
    toolchain = ctx.toolchains[ctx.attr._toolchain]

    cmake_binary = None
    for x in toolchain.data.target.files.to_list():
        if x.path.endswith("/bin/cmake"):
            cmake_binary = x
            break

    return [
        DefaultInfo(
            files = depset(direct = [cmake_binary]),
            runfiles = toolchain.data.target.default_runfiles,
        ),
    ]

cmake_binary = rule(
    implementation = _impl,
    attrs = {
        "_toolchain": attr.string(default = "@rules_foreign_cc//toolchains:cmake_toolchain"),
    },
    toolchains = [
        "@rules_foreign_cc//toolchains:cmake_toolchain",
    ],
)
