"""Yosys utilities"""

def _yosys_gen_action(ctx, mnemonic, tool, env):
    args = ctx.actions.args()

    out_replaces = {}
    for file, label in zip(ctx.outputs.outs, ctx.attr.outs):
        _, _, relative = str(label).partition("//")
        out_replaces["$(execpath {})".format(label)] = file
        out_replaces["$(execpath {})".format(relative)] = file

    for arg in ctx.attr.args:
        if arg in out_replaces:
            args.add(out_replaces[arg])
            continue

        expanded = ctx.expand_location(arg, ctx.attr.srcs)
        args.add(expanded)

    ctx.actions.run(
        executable = tool,
        arguments = [args],
        inputs = ctx.files.srcs,
        outputs = ctx.outputs.outs,
        mnemonic = mnemonic,
        env = env,
    )

    return [DefaultInfo(
        files = depset(ctx.outputs.outs),
    )]

def _find_m4(runfiles, label):
    m4 = None
    for file in runfiles:
        if file.basename in ["m4", "m4.exe"]:
            m4 = file
            break

    if not m4:
        fail("Failed to find m4 binary in runfiles of {}".format(label))

    return m4

def _yosys_bison_impl(ctx):
    m4 = _find_m4(ctx.attr.bison[DefaultInfo].default_runfiles.files.to_list(), ctx.attr.bison.label)

    env = {
        "BISON_PKGDATADIR": "{}.runfiles/{}/data".format(
            ctx.executable.bison.path,
            ctx.executable.bison.owner.workspace_name,
        ),
        "M4": "{}.runfiles/{}".format(
            ctx.executable.bison.path,
            m4.short_path[len("../"):],
        ),
    }

    return _yosys_gen_action(
        ctx = ctx,
        mnemonic = "YosysBisonGen",
        tool = ctx.executable.bison,
        env = env,
    )

yosys_bison = rule(
    doc = "An internal rule for running bison in the yosys project.",
    implementation = _yosys_bison_impl,
    attrs = {
        "args": attr.string_list(
            doc = "Arguments to pass to bison.",
            mandatory = True,
        ),
        "bison": attr.label(
            doc = "The bison binary.",
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "outs": attr.output_list(
            doc = "Outputs from bison.",
            mandatory = True,
        ),
        "srcs": attr.label_list(
            doc = "Sources to provide to bison.",
            mandatory = True,
            allow_files = True,
        ),
    },
)

def _yosys_flex_impl(ctx):
    m4 = _find_m4(ctx.attr.flex[DefaultInfo].default_runfiles.files.to_list(), ctx.attr.flex.label)

    env = {
        "M4": "{}.runfiles/{}".format(
            ctx.executable.flex.path,
            m4.short_path[len("../"):],
        ),
    }

    return _yosys_gen_action(
        ctx = ctx,
        mnemonic = "YosysFlexGen",
        tool = ctx.executable.flex,
        env = env,
    )

yosys_flex = rule(
    doc = "An internal rule for running flex in the yosys project.",
    implementation = _yosys_flex_impl,
    attrs = {
        "args": attr.string_list(
            doc = "Arguments to pass to flex.",
            mandatory = True,
        ),
        "flex": attr.label(
            doc = "The flex binary.",
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "outs": attr.output_list(
            doc = "Outputs from bison.",
            mandatory = True,
        ),
        "srcs": attr.label_list(
            doc = "Sources to provide to bison.",
            mandatory = True,
            allow_files = True,
        ),
    },
)
