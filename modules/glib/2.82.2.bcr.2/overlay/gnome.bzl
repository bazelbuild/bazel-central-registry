"""Custom Starlark macros and rules for gnome/glib."""

# https://github.com/mesonbuild/meson/blob/4fa52925459dac650bf053715987ee7beb3b23c1/mesonbuild/modules/gnome.py#L1847
def _mkenums_simple_impl(ctx):
    fhead = ""
    if ctx.attr.body_prefix:
        fhead += "%s\n" % ctx.attr.body_prefix
    fhead += '#include "%s"\n' % ctx.outputs.hdr_out.short_path
    for hdr in ctx.files.sources:
        fhead += '#include "%s"\n' % hdr.short_path
    fhead += """
#define C_ENUM(v) ((gint) v)
#define C_FLAGS(v) ((guint) v)
"""

    fprod = '\n/* enumerations from "@basename@" */\n'

    vhead = """
GType
{func_prefix}@enum_name@_get_type (void)
{{
    static gsize gtype_id = 0;
    static const G@Type@Value values[] = {{
""".format(func_prefix = ctx.attr.function_prefix)

    vprod = '    { C_@TYPE@(@VALUENAME@), "@VALUENAME@", "@valuenick@" },'

    vtail = """    { 0, NULL, NULL }
  };
  if (g_once_init_enter (&gtype_id)) {
      GType new_type = g_@type@_register_static (g_intern_static_string ("@EnumName@"), values);
      g_once_init_leave (&gtype_id, new_type);
  }
  return (GType) gtype_id;
}
"""

    args = ctx.actions.args()
    args.add("--output", ctx.outputs.src_out)
    args.add("--fhead", fhead)
    args.add("--fprod", fprod)
    args.add("--vhead", vhead)
    args.add("--vprod", vprod)
    args.add("--vtail", vtail)
    args.add_all(ctx.files.sources)
    ctx.actions.run(
        inputs = ctx.files.sources,
        outputs = [ctx.outputs.src_out],
        executable = ctx.executable._glib_mkenums,
        arguments = [args],
        mnemonic = "GnomeMkEnumsSimpleSrc",
        progress_message = "Generating {}".format(ctx.outputs.src_out.basename),
    )

    fhead = """
#pragma once

#include <glib-object.h>
{header_prefix}
G_BEGIN_DECLS
""".format(header_prefix = ctx.attr.header_prefix)

    fprod = '\n/* enumerations from "@basename@" */\n'

    vhead = """
{decl_decorator}
GType {func_prefix}@enum_name@_get_type (void);
#define @ENUMPREFIX@_TYPE_@ENUMSHORT@ ({func_prefix}@enum_name@_get_type())
""".format(
        decl_decorator = ctx.attr.decorator,
        func_prefix = ctx.attr.function_prefix,
    )

    ftail = "\nG_END_DECLS\n"

    args = ctx.actions.args()
    args.add("--output", ctx.outputs.hdr_out)
    args.add("--fhead", fhead)
    args.add("--fprod", fprod)
    args.add("--vhead", vhead)
    args.add("--ftail", ftail)
    args.add_all(ctx.files.sources)
    ctx.actions.run(
        inputs = ctx.files.sources,
        outputs = [ctx.outputs.hdr_out],
        executable = ctx.executable._glib_mkenums,
        arguments = [args],
        mnemonic = "GnomeMkEnumsSimpleHdr",
        progress_message = "Generating {}".format(ctx.outputs.hdr_out.basename),
    )

    return [
        DefaultInfo(files = depset([ctx.outputs.hdr_out, ctx.outputs.src_out])),
    ]

# These attributes map to the ones of gnome.mkenums_simple()
# https://mesonbuild.com/Gnome-module.html#gnomemkenums_simple.
_mkenums_simple_attrs = {
    "body_prefix": attr.string(
        doc = "Additional prefix at the top of the body file, e.g. for extra includes.",
    ),
    "decorator": attr.string(
        doc = "Optional decorator for the function declarations, e.g. GTK_AVAILABLE or GST_EXPORT.",
    ),
    "function_prefix": attr.string(
        doc = "Additional prefix for function names, e.g. in case you want to add a leading underscore to functions used only internally.",
    ),
    "header_prefix": attr.string(
        doc = "Additional prefix at the top of the header file, e.g. for extra includes (which may be needed if you specify a decorator for the function declarations).",
    ),
    "identifier_prefix": attr.string(
        doc = "Prefix to use for the identifiers.",
    ),
    "sources": attr.label_list(
        mandatory = True,
        allow_files = True,
        doc = "The list of sources to make enums with.",
    ),
    "symbol_prefix": attr.string(
        doc = "Prefix to use for the symbols.",
    ),
    "hdr_out": attr.output(
        mandatory = True,
        doc = "The generated header file.",
    ),
    "src_out": attr.output(
        mandatory = True,
        doc = "The generated source file.",
    ),
    "_glib_mkenums": attr.label(
        default = Label("//gobject:glib_mkenums"),
        executable = True,
        cfg = "exec",
    ),
}

# This command mimics the meson command gnome.mkenums_simple():
# https://mesonbuild.com/Gnome-module.html#gnomemkenums_simple
mkenums_simple = rule(
    _mkenums_simple_impl,
    attrs = _mkenums_simple_attrs,
)
