"""Rules for building MPFR with Bazel."""

def _mpfr_copy_impl(ctx):
    ctx.actions.symlink(
        output = ctx.outputs.out,
        target_file = ctx.file.src,
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

mpfr_copy = rule(
    doc = "Creates a symlink to place a source file at a specific path in the output tree.",
    implementation = _mpfr_copy_impl,
    attrs = {
        "out": attr.output(
            doc = "The output path for the symlink.",
            mandatory = True,
        ),
        "src": attr.label(
            doc = "The source file to symlink.",
            mandatory = True,
            allow_single_file = True,
        ),
    },
)

def _mpfr_gen_patches_impl(ctx):
    args = ctx.actions.args()
    args.add(ctx.outputs.out)
    args.add(ctx.file.patches)
    ctx.actions.run(
        outputs = [ctx.outputs.out],
        inputs = [ctx.file.patches],
        executable = ctx.executable._tool,
        arguments = [ctx.outputs.out.path, ctx.file.patches.path],
        mnemonic = "MpfrGenPatches",
        progress_message = "MpfrGenPatches %{label}",
    )
    return [DefaultInfo(
        files = depset([ctx.outputs.out]),
    )]

mpfr_gen_patches = rule(
    doc = "Generates get_patches.c from the MPFR PATCHES file.",
    implementation = _mpfr_gen_patches_impl,
    attrs = {
        "out": attr.output(
            doc = "The output get_patches.c file.",
            mandatory = True,
        ),
        "patches": attr.label(
            doc = "The PATCHES file listing applied patches.",
            mandatory = True,
            allow_single_file = True,
        ),
        "_tool": attr.label(
            default = Label("//bazel:gen_get_patches"),
            executable = True,
            cfg = "exec",
        ),
    },
)
