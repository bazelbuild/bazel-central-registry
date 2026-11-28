"""Mark a checked-in script executable, including when applied as a BCR overlay."""

def _impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file.src,
        output = ctx.outputs.out,
        substitutions = {},
        is_executable = True,
    )

executable_script = rule(
    implementation = _impl,
    attrs = {
        "out": attr.output(mandatory = True),
        "src": attr.label(allow_single_file = True, mandatory = True),
    },
)
