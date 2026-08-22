"""An executable copy of a source file.

Overlay files arrive over HTTP with whatever mode the fetcher gives them, and a
checked-out registry has no mode bits worth relying on either -- but sh_binary
and sh_test execute their `srcs` directly, so the bit has to come from
somewhere. Bazel is that somewhere: `ctx.actions.symlink(is_executable = True)`
makes the guarantee part of the graph instead of a property of the checkout.
"""

def _executable_file_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.symlink(
        output = out,
        target_file = ctx.file.src,
        is_executable = True,
    )
    return [DefaultInfo(files = depset([out]))]

executable_file = rule(
    implementation = _executable_file_impl,
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The script to make executable.",
        ),
    },
    doc = "Exposes a source file as an executable one, mode bits regardless.",
)
