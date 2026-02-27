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
        generated_header = True,
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
        generated_header (bool, optional): Whether or not to add a header comment that the Makefile adds to generated sources. Defaults to True,
        is_windows (bool, optional): Whether or not to generate a bat command.

    Returns:
        str: The sed command
    """
    sed_args = []

    if generated_header:
        sed_args.append("-e '1 i\\/* DO NOT EDIT! GENERATED AUTOMATICALLY! */' \\")

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
