"""`gawk_tool` - a rule for bundling a `gawk` executable with additional awk extensions."""

def _gawk_tool_impl(ctx):
    gawk_binary = ctx.executable._gawk

    # Symlink the provided extensions to a single clean directory.
    # Without a clean directory for extensions, awk will try (and fail) to load the incorrect
    # file (e.g. `filefuncs`) instead of the correct dynamic lib file (e.g. `filefuncs.so`).
    extensions_dir = ctx.label.name + ".extensions"
    extension_symlinks = []
    for extension in ctx.files.extensions:
        symlink = ctx.actions.declare_file("{}/{}".format(extensions_dir, extension.basename))
        ctx.actions.symlink(output = symlink, target_file = extension)
        extension_symlinks.append(symlink)

    runfiles = ctx.runfiles(
        files = ctx.files.extensions + extension_symlinks,
    )
    runfiles = runfiles.merge(ctx.attr._gawk[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge(ctx.attr._runfiles_lib[DefaultInfo].default_runfiles)

    script = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.expand_template(
        output = script,
        template = ctx.file._template,
        substitutions = {
            "$$WORKSPACE_NAME$$": ctx.workspace_name,
            "$$GAWK$$": ctx.executable._gawk.short_path,
            # We provide the path to an actual extension, so that our script can look it
            # up in the runfiles using `rlocation`, and derive the extension dir from that.
            # We can't just provide the path to the extension dir, because it doesn't have
            # an entry in the runfiles manifest, and doesn't get resolved by `rlocation`.
            "$$SAMPLE_EXTENSION$$": extension_symlinks[0].short_path,
        },
        is_executable = True,
    )

    return [DefaultInfo(executable = script, runfiles = runfiles)]

def _runfiles_relative_path(ctx, file):
    repo_name = ctx.workspace_name
    if file.owner and file.owner.repo_name:
        repo_name = file.owner.repo_name
    return "{}/{}".format(repo_name, file.short_path)

gawk_tool = rule(
    implementation = _gawk_tool_impl,
    doc = """\
Create a `gawk` binary with additional awk extensions.

There are a number of built-in extensions available in `@gawk//extensions`, such as `@gawk//extensions:filefuncs`. You
can also build your own extensions and use this rule to include them. See
[Writing Extensions for `gawk`](https://www.gnu.org/software/gawk/manual/html_node/Dynamic-Extensions.html).

If you have no need for awk extensions, use `@gawk` directly instead.
""",
    attrs = {
        "extensions": attr.label_list(
            allow_files = True,
            allow_empty = False,
            doc = """\
Extensions to bundle with gawk and make discoverable at runtime.
Each of these must be a dynamic library artifact.
""",
        ),
        "_gawk": attr.label(
            default = "//:gawk",
            executable = True,
            cfg = "target",
        ),
        "_template": attr.label(
            default = "//:gawk_tool.sh.tpl",
            allow_single_file = True,
        ),
        "_runfiles_lib": attr.label(
            default = "@rules_shell//shell/runfiles",
        ),
    },
    executable = True,
)
