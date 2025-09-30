"""Yosys utilities"""

def _yosys_bison_impl(ctx):
    output = ctx.actions.declare_file("{}{}".format(
        ctx.label.name,
        "" if "." in ctx.label.name else ".txt",
    ))

    m4 = None
    for file in ctx.attr.bison[DefaultInfo].default_runfiles.files.to_list():
        if file.basename in ["m4", "m4.exe"]:
            m4 = file
            break

    if not m4:
        fail("Failed to find m4 binary in runfiles of {}".format(ctx.attr.bison.label))

    args = ctx.actions.args()

    for arg in ctx.attr.args:
        expanded = ctx.expand_location(arg, ctx.attr.srcs + ctx.attr.outs)
        args.add(expanded)

    ctx.actions.run(
        outputs = [output],
        executable = ctx.executable.bison,
        arguments = [args],
        mnemonic = "YosysBisonGen",
        env = {
            "BISON_PKGDATADIR": "{}.runfiles/{}/data".format(
                ctx.executable.bison.path,
                ctx.executable.bison.owner.workspace_name,
            ),
            "M4": "{}.runfiles/{}/{}".format(
                ctx.executable.bison.path,
                ctx.executable.bison.owner.workspace_name,
                m4.short_path[len("../"):],
            ),
        },
    )

    return [DefaultInfo(
        files = depset(ctx.outputs.outs),
    )]

yosys_bison = rule(
    doc = "An internal rule for running bison in the yosys project.",
    implementation = _yosys_bison_impl,
    attrs = {
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
    output = ctx.actions.declare_file("{}{}".format(
        ctx.label.name,
        "" if "." in ctx.label.name else ".txt",
    ))

    m4 = None
    for file in ctx.attr.flex[DefaultInfo].default_runfiles.files.to_list():
        if file.basename in ["m4", "m4.exe"]:
            m4 = file
            break

    if not m4:
        fail("Failed to find m4 binary in runfiles of {}".format(ctx.attr.flex.label))

    args = ctx.actions.args()

    for arg in ctx.attr.args:
        expanded = ctx.expand_location(arg, ctx.attr.srcs + ctx.attr.outs)
        args.add(expanded)

    ctx.actions.run(
        outputs = [output],
        executable = ctx.executable.flex,
        arguments = [args],
        mnemonic = "YosysFlexGen",
        env = {
            "M4": "{}.runfiles/{}/{}".format(
                ctx.executable.flex.path,
                ctx.executable.flex.owner.workspace_name,
                m4.short_path[len("../"):],
            ),
        },
    )

    return [DefaultInfo(
        files = depset(ctx.outputs.outs),
    )]

yosys_flex = rule(
    doc = "An internal rule for running flex in the yosys project.",
    implementation = _yosys_flex_impl,
    attrs = {
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
