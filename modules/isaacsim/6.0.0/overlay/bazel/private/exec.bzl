"""An executable copy of a source file.

Overlay files arrive over HTTP with whatever mode the fetcher gives them, and a
checked-out registry has no mode bits worth relying on either -- but sh_binary
and sh_test execute their `srcs` directly, so the bit has to come from
somewhere. Bazel is that somewhere: `ctx.actions.symlink(is_executable = True)`
makes the guarantee part of the graph instead of a property of the checkout.
"""

def _executable_file_impl(ctx):
    ctx.actions.symlink(
        output = ctx.outputs.out,
        target_file = ctx.file.src,
        is_executable = True,
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

executable_file = rule(
    implementation = _executable_file_impl,
    attrs = {
        "out": attr.output(
            mandatory = True,
            doc = "Filename of the executable copy.",
        ),
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The script to make executable.",
        ),
    },
    doc = "Exposes a source file as an executable one, mode bits regardless.",
)
