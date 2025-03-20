"""A wrapper around glib-mkenums"""

def _mkenums_impl(ctx):
    inputs = list(ctx.files.srcs)
    args = ctx.actions.args()
    for key in ["fhead", "fprod", "ftail", "eprod", "vhead", "vprod", "vtail"]:
        value = getattr(ctx.attr, key)
        if value:
            args.add_all(value, format_each = "--" + key + "=%s")
    for key in ["comments", "identifier_prefix", "symbol_prefix"]:
        value = getattr(ctx.attr, key)
        if value:
            args.add("--" + key.replace("_", "-"), value)
    if ctx.attr.template:
        args.add("--template", ctx.file.template)
        inputs.append(ctx.file.template)
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
    "fhead": attr.string_list(doc = "Same as `fhead` in glib-mkenums."),
    "fprod": attr.string_list(doc = "Same as `fprod` in glib-mkenums."),
    "ftail": attr.string_list(doc = "Same as `ftail` in glib-mkenums."),
    "eprod": attr.string_list(doc = "Same as `eprod` in glib-mkenums."),
    "vhead": attr.string_list(doc = "Same as `vhead` in glib-mkenums."),
    "vprod": attr.string_list(doc = "Same as `vprod` in glib-mkenums."),
    "vtail": attr.string_list(doc = "Same as `vtail` in glib-mkenums."),
    "comments": attr.string(doc = "Same as `comments` in glib-mkenums."),
    "identifier_prefix": attr.string(doc = "Same as `identifier-prefix` in glib-mkenums."),
    "symbol_prefix": attr.string(doc = "Same as `symbol-prefix` in glib-mkenums."),
    "template": attr.label(allow_single_file = True, doc = "Same as `fhead` in glib-mkenums."),
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
