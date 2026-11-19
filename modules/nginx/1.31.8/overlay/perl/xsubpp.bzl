"""Translate XS with the Perl interpreter selected for the execution platform."""

def _xsubpp_impl(ctx):
    perl = ctx.toolchains["@rules_perl//perl:exec_toolchain_type"].perl_runtime
    out = ctx.actions.declare_file(ctx.label.name + ".c")
    args = ctx.actions.args()

    args.add(ctx.file._xsubpp)
    args.add_all(ctx.files.typemaps, before_each = "--typemap")
    args.add("--output", out)
    args.add(ctx.file.src)
    ctx.actions.run(
        executable = perl.interpreter,
        arguments = [args],
        inputs = depset([ctx.file._xsubpp, ctx.file.src] + ctx.files.typemaps, transitive = [perl.runtime]),
        outputs = [out],
        mnemonic = "PerlXS",
        toolchain = "@rules_perl//perl:exec_toolchain_type",
    )
    return [DefaultInfo(files = depset([out]))]

perl_xsubpp = rule(
    implementation = _xsubpp_impl,
    attrs = {
        "src": attr.label(allow_single_file = [".xs"], mandatory = True),
        "typemaps": attr.label_list(allow_files = True),
        "_xsubpp": attr.label(
            default = Label("@rules_perl//perl/private:xsubpp"),
            allow_single_file = True,
            cfg = "exec",
        ),
    },
    toolchains = ["@rules_perl//perl:exec_toolchain_type"],
)
