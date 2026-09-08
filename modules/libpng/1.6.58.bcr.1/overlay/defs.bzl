def _gen_libpngconf_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    tmp = ctx.actions.declare_file(ctx.attr.out + ".tmp")
    extra_png_settings = ["#pragma once"]
    if ctx.attr.disable_exif:
        extra_png_settings += ["#undef PNG_READ_eXIf_SUPPORTED"]
    ctx.actions.write(tmp, "\n".join(extra_png_settings))
    ctx.actions.run_shell(
        inputs = [ctx.file.src, tmp],
        outputs = [out],
        command = 'cat "$1" "$2" > "$3"',
        arguments = [ctx.file.src.path, tmp.path, out.path]
    )
    return [DefaultInfo(files = depset([out]))]

gen_pnglibconf = rule(
    implementation = _gen_libpngconf_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
        "out": attr.string(mandatory = True),
        "disable_exif": attr.bool(),
    },
)
