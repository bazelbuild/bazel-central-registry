"""Bison Bazel utilities"""

_CMD_TEMPLATE = "$(execpath {}) $(execpath {{template}}) {} > $@"

_REPLACE_TEMPLATE = "-e 's|{}|{}|g' \\"

_INLINE_TEMPLATE = "-e '/{}/r $(execpath {})' \\"

_DELETE_TEMPLATE = "-e '/{}/d' \\"

def sed_command(
        *,
        sed,
        template,
        automake_vars,
        inline_vars,
        delete_vars,
        direct_vars,
        use_direct_vars = False,
        is_windows = False):
    """Generate a sed command for producing generated bison source files.

    Args:
        sed (label): The label of a sed executable
        template (label): The label of the template
        automake_vars (dict): Mappings of key value automake pairs.
        inline_vars (dict): Mappings of keys to source files to inline.
        delete_vars (list): Deletion keys for removing lines.
        direct_vars (dict): Mappings of template keys to variables.
        use_direct_vars (bool, optional): Whether or not to use `direct_vars` at all.
        is_windows (bool, optional): Whether or not to generate a bat command.

    Returns:
        str: The sed command
    """
    sed_args = []
    for key, val in automake_vars.items():
        sed_args.append(_REPLACE_TEMPLATE.format(key, val))

    for key, val in inline_vars.items():
        sed_args.append(_INLINE_TEMPLATE.format(key, val))

    if use_direct_vars:
        for key, val in direct_vars.items():
            sed_args.append(_REPLACE_TEMPLATE.format(key, val))

    for key in delete_vars:
        sed_args.append(_DELETE_TEMPLATE.format(key))

    command = _CMD_TEMPLATE.format(
        sed,
        "\n".join(sed_args).strip("\\\n"),
    ).replace("{template}", template)

    if is_windows:
        return command.replace("\\\n", "^\n\r")

    return command

def _bison_version_output_impl(ctx):
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

    ctx.actions.run_shell(
        outputs = [output],
        tools = [ctx.executable.bison],
        mnemonic = "BisonVersionOutputGen",
        command = "{} --version > {}".format(
            ctx.executable.bison.path,
            output.path,
        ),
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
        files = depset([output]),
    )]

bison_version_output = rule(
    doc = "An internal rule for testing bison executions.",
    implementation = _bison_version_output_impl,
    attrs = {
        "bison": attr.label(
            doc = "The bison binary.",
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
    },
)
