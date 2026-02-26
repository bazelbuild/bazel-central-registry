"""Rule for assembling the yosys share/ directory from techlibs sources."""

def _share_tree_impl(ctx):
    """Copy techlib source files into a share/ TreeArtifact.

    'data' is the deduplicated list of source files (Bazel labels).
    'mappings' is a list of "source/path:dest/path" strings; the same source
    may appear multiple times with different destinations (renames, shared
    files placed into multiple arch subdirs).
    """
    share_dir = ctx.actions.declare_directory(ctx.attr.dir_name)

    # Build a map from workspace-relative source path to File object.
    # f.path for external-repo files is "external/<repo>/<ws-rel-path>"; strip
    # the "external/<repo>/" prefix so mappings can use plain workspace paths.
    def _ws_rel(f):
        p = f.path
        if p.startswith("external/"):
            sep = p.find("/", len("external/"))
            if sep >= 0:
                return p[sep + 1:]
        return p

    src_map = {_ws_rel(f): f for f in ctx.files.data}

    cmds = ["mkdir -p " + share_dir.path]
    for mapping in ctx.attr.mappings:
        src_key, dst = mapping.split(":", 1)
        # Look up by the label's short path (relative to workspace root).
        src_file = src_map.get(src_key)
        if src_file == None:
            fail("share_tree: source file not found in data: " + src_key)
        dest = share_dir.path + "/" + dst
        cmds.append("mkdir -p $(dirname {})".format(dest))
        cmds.append("cp {} {}".format(src_file.path, dest))

    ctx.actions.run_shell(
        inputs = ctx.files.data,
        outputs = [share_dir],
        command = " && \\\n  ".join(cmds),
    )
    return [DefaultInfo(files = depset([share_dir]))]

share_tree = rule(
    implementation = _share_tree_impl,
    attrs = {
        # Unique set of source files (no duplicates allowed by Bazel).
        "data": attr.label_list(allow_files = True),
        # Copy instructions: "workspace/relative/src:dest/within/share" pairs.
        # The same source may appear multiple times with different destinations.
        "mappings": attr.string_list(),
        "dir_name": attr.string(default = "share"),
    },
)
