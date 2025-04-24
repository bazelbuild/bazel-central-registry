"""A wrapper around glib-mkenums"""

def _mkenums_impl(ctx):
    inputs = list(ctx.files.srcs)
    args = ctx.actions.args()
    template = "--template"
    if ctx.attr.template:
        inputs.append(ctx.file.template)
        args.add(template, ctx.file.template)
    if ctx.attr.options:
        if any([template in option for option in ctx.attr.options]):
            fail("`" + template + "` must be specified via the respective rule attribute.")
        args.add_all(ctx.attr.options)
    args.add("--output", ctx.outputs.out)
    args.add_all(ctx.files.srcs)
    ctx.actions.run(
        inputs = inputs,
        outputs = [ctx.outputs.out],
        executable = ctx.executable._glib_mkenums,
        arguments = [args],
        mnemonic = "GlibMkenums",
        progress_message = "Generating {}".format(ctx.outputs.out.basename),
    )
    return DefaultInfo(files = depset([ctx.outputs.out]))

# See https://gitlab.gnome.org/GNOME/glib/-/blob/2.82.2/docs/reference/gobject/glib-mkenums.rst
# for the description of all options.
_mkenums_attrs = {
    "template": attr.label(allow_single_file = True, doc = "See `template` in the glib-mkenums command."),
    "options": attr.string_list(doc = "Additional options to pass to the glib-mkenums command, must not contain `--template`."),
    "srcs": attr.label_list(
        mandatory = True,
        allow_files = True,
        doc = "The list of sources to make enums with.",
    ),
    "out": attr.output(
        mandatory = True,
        doc = "The generated file.",
    ),
    "_glib_mkenums": attr.label(
        default = Label("//gobject:glib_mkenums"),
        executable = True,
        cfg = "exec",
    ),
}

mkenums = rule(
    _mkenums_impl,
    attrs = _mkenums_attrs,
)
