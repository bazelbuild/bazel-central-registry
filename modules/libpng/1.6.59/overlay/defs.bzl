"""Rule for generating pnglibconf.h for libpng"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _gen_libpngconf_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    options = ctx.attr.options_flag[BuildSettingInfo].value
    substitutions = {}
    if options:
        for op in options:
            if len(op) < 5 or op[0] not in ["-", "+"] or op[1:5] != "PNG_":
                fail("Invalid gen_pnglibconf option: ", op)
            png_op = op[1:]
            png_op_on = "#define " + png_op
            png_op_off = "/*#undef " + png_op + "*/"
            if op[0] == "-":
                substitutions[png_op_on] = png_op_off
            else:
                substitutions[png_op_off] = png_op_on
    ctx.actions.expand_template(
        template = ctx.file.src,
        output = out,
        substitutions = substitutions,
    )
    return [DefaultInfo(files = depset([out]))]

gen_pnglibconf = rule(
    implementation = _gen_libpngconf_impl,
    doc = """
Generates out (pnglibconf.h) from src (scripts/pnglibconf.h.prebuilt) with
optional behavior enabled or disabled via options_flag.
""",
    attrs = {
        "options_flag": attr.label(
            doc = """
A string_list flag with strings of the form `+PNG_OPTION_NAME` or
`-PNG_OPTION_NAME`, where `PNG_OPTION_NAME` is an option listed in src. The
`+` form enables an option which is disabled, and the `-` form disables an
option which is enabled by default.
""",
        ),
        "out": attr.string(
            doc = "Output file",
            mandatory = True,
        ),
        "src": attr.label(
            allow_single_file = True,
            doc = "Input file that contains defaults for PNG options",
            mandatory = True,
        ),
    },
)
