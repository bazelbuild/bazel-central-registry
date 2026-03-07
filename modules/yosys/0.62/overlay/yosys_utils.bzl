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

# Rules for assembling the yosys share/ directory from techlibs sources.
# Most files are linked from the techlibs source. The files in directory common
# end up in the root share directory. All others remain in their directory, e.g.
#   techlibs/common/gate2lutv      => share/gate2lutv
#   techlibs/microchip/arith_map.v => share/microchip/arith_map.v
# Some files do not follow that general rule. Those are renamed.

def share_dst(src):
    """Map a techlibs/ source path to its share/ destination.

    techlibs/common/X  -> X
    techlibs/VENDOR/X  -> VENDOR/X
    """
    if src.startswith("techlibs/common/"):
        return src[len("techlibs/common/"):]
    return src[len("techlibs/"):]

def _share_tree_impl(ctx):
    share_outputs = []

    # --- Primary 1:1 mappings via label_keyed_string_dict ---
    # Build a path->File map for rename lookups while processing primary mappings.
    src_path_map = {}
    for target, dst in ctx.attr.file_map.items():
        files = target.files.to_list()
        if len(files) != 1:
            fail("share_tree: label must resolve to exactly one file: " + str(target.label))
        src_file = files[0]
        short = src_file.short_path
        if short.startswith("../"):
            short = short.split("/", 2)[2]
        src_path_map[short] = src_file
        out = ctx.actions.declare_file(ctx.attr.dir_name + "/" + dst)
        ctx.actions.symlink(output = out, target_file = src_file)
        share_outputs.append(out)

    # --- Rename/extra-destination mappings ---
    for mapping in ctx.attr.renames:
        src_key, dst = mapping.split(":", 1)
        src_file = src_path_map.get(src_key)
        if src_file == None:
            fail("share_tree: rename source not found in file_map: " + src_key)
        out = ctx.actions.declare_file(ctx.attr.dir_name + "/" + dst)
        ctx.actions.symlink(output = out, target_file = src_file)
        share_outputs.append(out)

    return [DefaultInfo(files = depset(share_outputs))]

share_tree = rule(
    implementation = _share_tree_impl,
    doc = (
        "Generates the share file tree for yosys by linking to the right\n" +
        "files in the source repository."
    ),
    attrs = {
        "dir_name": attr.string(
            doc = "Name of the top-level output directory for the generated share tree.",
            default = "share",
        ),
        "file_map": attr.label_keyed_string_dict(
            doc = "Primary 1:1 mappings: {source_label: destination_within_share}",
            allow_files = True,
        ),
        "renames": attr.string_list(
            doc = (
                "Extra rename mappings for files needing multiple destinations.\n" +
                "Format: workspace/relative/src:dest/within/share"
            ),
        ),
    },
)
