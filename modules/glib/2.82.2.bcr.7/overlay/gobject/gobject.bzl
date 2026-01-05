"""Wrappers around glib-mkenums and glib-genmarshal"""

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

def _add_genmarshal_action(ctx, output, mode):
    args = ctx.actions.args()
    if mode == "header":
        args.add("--header")
    elif mode == "body":
        args.add("--body")
    else:
        fail("mode must be 'header' or 'body'")
    args.add("--prefix", ctx.attr.prefix)
    args.add("--output", output)
    args.add(ctx.file.src)

    ctx.actions.run(
        inputs = [ctx.file.src],
        outputs = [output],
        executable = ctx.executable._glib_genmarshal,
        arguments = [args],
        mnemonic = "GlibGenmarshal",
        progress_message = "Generating {}".format(output.basename),
    )

def _genmarshal_impl(ctx):
    outputs = []
    if ctx.attr.out and (ctx.attr.out_header or ctx.attr.out_body):
        fail("out cannot be used with out_header/out_body")

    if ctx.attr.out:
        if not ctx.attr.mode:
            fail("mode must be set when using out")
        _add_genmarshal_action(ctx, ctx.outputs.out, ctx.attr.mode)
        outputs.append(ctx.outputs.out)

    if ctx.attr.out_header:
        _add_genmarshal_action(ctx, ctx.outputs.out_header, "header")
        outputs.append(ctx.outputs.out_header)

    if ctx.attr.out_body:
        _add_genmarshal_action(ctx, ctx.outputs.out_body, "body")
        outputs.append(ctx.outputs.out_body)

    if not outputs:
        fail("one of out or out_header/out_body is required")

    return DefaultInfo(files = depset(outputs))

_genmarshal_attrs = {
    "src": attr.label(allow_single_file = True, mandatory = True),
    "out": attr.output(),
    "mode": attr.string(),
    "out_header": attr.output(),
    "out_body": attr.output(),
    "prefix": attr.string(default = ""),
    "_glib_genmarshal": attr.label(
        default = Label("//gobject:glib_genmarshal"),
        executable = True,
        cfg = "exec",
    ),
}

genmarshal = rule(
    _genmarshal_impl,
    attrs = _genmarshal_attrs,
)
