"""Rule that bootstraps the NVC VHDL standard libraries.

The freshly built `nvc` compiler is run over the library sources to produce the
runtime library tree (STD, IEEE, NVC, ... for VHDL-1993/2008/2019).  This is
the Bazel equivalent of the autotools `make bootstrap` target.
"""

def _nvc_bootstrap_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.out_dir)

    args = ctx.actions.args()
    args.add(ctx.file._script)
    args.add(ctx.executable.compiler)
    args.add(out.path)
    args.add_all(ctx.files.deps)

    ctx.actions.run_shell(
        outputs = [out],
        inputs = depset(
            direct = ctx.files.srcs + ctx.files.deps + [ctx.file._script],
        ),
        tools = [ctx.executable.compiler],
        arguments = [args],
        command = 'exec bash "$@"',
        mnemonic = "NvcBootstrap",
        progress_message = "Bootstrapping NVC standard libraries into %{output}",
    )

    return [DefaultInfo(files = depset([out]))]

nvc_bootstrap = rule(
    implementation = _nvc_bootstrap_impl,
    doc = "Run nvc to analyse the VHDL standard libraries into a library tree.",
    attrs = {
        "compiler": attr.label(
            doc = "The nvc compiler binary used to analyse the libraries.",
            executable = True,
            cfg = "exec",
            mandatory = True,
        ),
        "srcs": attr.label_list(
            doc = "All VHDL sources for the standard libraries.",
            allow_files = [".vhd", ".vhdl"],
            mandatory = True,
        ),
        "deps": attr.label_list(
            doc = "The lib/*/deps.mk dependency manifests.",
            allow_files = [".mk"],
            mandatory = True,
        ),
        "out_dir": attr.string(
            doc = "Name of the generated library tree directory.",
            default = "lib",
        ),
        "_script": attr.label(
            default = Label("//bazel:bootstrap.bash"),
            allow_single_file = True,
        ),
    },
)
