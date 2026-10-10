"""Starlark helpers for the pkgconf overlay. Not upstream."""

visibility("private")

def _pkg_config_alias_impl(ctx):
    # Whatever suffix makes pkgconf executable -- `.exe` on Windows, nothing
    # elsewhere -- is by definition the one the alias needs too.
    pkgconf = ctx.executable.pkgconf
    suffix = "." + pkgconf.extension if pkgconf.extension else ""

    out = ctx.actions.declare_file(ctx.label.name + suffix)
    ctx.actions.symlink(
        output = out,
        target_file = pkgconf,
        is_executable = True,
    )

    # pkgconf's own runfiles carry the binary the symlink resolves to.
    return DefaultInfo(
        executable = out,
        files = depset([out]),
        runfiles = ctx.runfiles(files = [out]).merge(
            ctx.attr.pkgconf[DefaultInfo].default_runfiles,
        ),
    )

pkg_config_alias = rule(
    implementation = _pkg_config_alias_impl,
    attrs = {
        "pkgconf": attr.label(
            # Not `allow_single_file`: a binary target may have more than one
            # default output.
            allow_files = True,
            cfg = "target",
            executable = True,
            mandatory = True,
            doc = "The pkgconf binary to publish under this target's name.",
        ),
    },
    executable = True,
    doc = """\
Symlinks `pkgconf` to this target's name, keeping its extension.

Bazel's own `alias` renames the label but not the artifact, and the artifact's
name is the entire point: a build system that shells out to `pkg-config` finds
it on `PATH`, and Windows will only run it if the file is called
`pkg-config.exe`.
""",
)

def _rlocationpath(file, workspace_name):
    # A file from another repository is rooted at `../<canonical name>` within
    # the runfiles; anything else belongs to the repository being built.
    if file.short_path.startswith("../"):
        return file.short_path[len("../"):]
    return workspace_name + "/" + file.short_path

def _runfiles_filelist_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".filelist")
    ctx.actions.write(
        output = out,
        content = "".join([
            _rlocationpath(file, ctx.workspace_name) + "\n"
            for file in ctx.files.srcs
        ]),
    )

    # The list is only useful alongside the files it names, so carry both.
    return DefaultInfo(
        files = depset([out]),
        runfiles = ctx.runfiles(files = ctx.files.srcs + [out]),
    )

runfiles_filelist = rule(
    implementation = _runfiles_filelist_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Files to list, and to carry as runfiles alongside the list.",
        ),
    },
    doc = """\
Writes one `Rlocation` path per line, in `srcs` order, to `<name>.filelist`,
and puts `srcs` in the runfiles of whatever depends on it.

The runfiles libraries resolve a path but cannot enumerate one, so a test that
has to rebuild a directory from a runfiles manifest needs the list of files to
rebuild it from to come from the build. See `bazel_test_main.cc`.
""",
)
