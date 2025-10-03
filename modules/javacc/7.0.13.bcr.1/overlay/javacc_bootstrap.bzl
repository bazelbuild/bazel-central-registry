def _javacc_bootstrap(ctx):
    outs = []
    java_outs = []
    jj_outs = []
    for out_basename in ctx.attr.outs:
        out = ctx.actions.declare_file(ctx.attr.name + "/" + out_basename)
        outs.append(out)
        if out_basename.endswith(".java"):
            java_outs.append(out)
        if out_basename.endswith(".jj"):
            jj_outs.append(out)
    ctx.actions.run(
        outputs = outs,
        inputs = ctx.files.src,
        executable = ctx.executable.javacc,
        arguments = [
            "-OUTPUT_DIRECTORY:" + outs[0].dirname,
            ctx.file.src.path,
        ],
        mnemonic = "JavaccBootstrap",
    )
    return [
        DefaultInfo(files = depset(outs)),
        OutputGroupInfo(
            jj_files = depset(jj_outs),
            java_files = depset(java_outs),
        ),
    ]

javacc_bootstrap = rule(
    implementation = _javacc_bootstrap,
    attrs = {
        "javacc": attr.label(
            executable = True,
            cfg = "exec",
        ),
        "src": attr.label(
            allow_single_file = True,
        ),
        "outs": attr.string_list(),
    },
)
