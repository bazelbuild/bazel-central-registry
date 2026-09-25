"""Lays the prebuilt Kit extensions out as a directory Kit accepts.

Kit takes extensions as `--ext-folder <dir>`, one directory holding
`<packageId>/config/extension.toml` per extension. The prebuilt extensions
arrive as one Bazel repository each, so something has to put them under a single
root, named the way Kit names them.

That layout is a runfiles layout, so Bazel builds it: `root_symlinks` places
every file of every package at `_isaacsim_kit_exts/<packageId>/…` in the
runfiles tree. The alternative -- staging the files at their own paths and
assembling a symlink farm in the launcher at run time -- puts a directory Kit
depends on outside anything Bazel tracks.

Naming the entries by **registry packageId** is not cosmetic: Kit identifies a
package partly by the name of the directory holding it, and entries named after
their Bazel repository make Kit fail to resolve dependency versions locally and
fall back to downloading from the registry.
"""

# Directory in the runfiles root that the extensions are laid out under. The
# marker file gives the launcher something to rlocation() its way to, which
# works whether runfiles are a real tree or a manifest.
_EXT_ROOT = "_isaacsim_kit_exts"

EXT_FOLDER_MARKER = _EXT_ROOT + "/.kit_ext_folder"

def _repo_relative(file):
    """The path of `file` within its own repository."""

    # An external repository's files are ../<canonical repo name>/<path>.
    if file.short_path.startswith("../"):
        return file.short_path.split("/", 2)[2]
    return file.short_path

def _kit_prebuilt_ext_folder_impl(ctx):
    root_symlinks = {}
    for target, package_id in ctx.attr.packages.items():
        for f in target[DefaultInfo].files.to_list():
            root_symlinks["{root}/{pkg}/{rel}".format(
                root = _EXT_ROOT,
                pkg = package_id,
                rel = _repo_relative(f),
            )] = f

    marker = ctx.actions.declare_file(ctx.label.name + ".marker")
    ctx.actions.write(
        marker,
        "%d Kit extension packages\n" % len(ctx.attr.packages),
    )
    root_symlinks[EXT_FOLDER_MARKER] = marker

    return [DefaultInfo(
        files = depset([marker]),
        runfiles = ctx.runfiles(root_symlinks = root_symlinks),
    )]

kit_prebuilt_ext_folder = rule(
    implementation = _kit_prebuilt_ext_folder_impl,
    attrs = {
        "packages": attr.label_keyed_string_dict(
            allow_files = True,
            mandatory = True,
            doc = "Extension file group -> its registry packageId.",
        ),
    },
    doc = "Stages the prebuilt Kit extensions as one --ext-folder in runfiles.",
)
