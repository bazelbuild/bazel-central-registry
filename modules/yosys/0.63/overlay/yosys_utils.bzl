"""Yosys utilities"""

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
