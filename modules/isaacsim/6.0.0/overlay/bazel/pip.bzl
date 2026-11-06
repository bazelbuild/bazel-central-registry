"""Assemble a pip prebundle: the vendored wheels an extension puts on sys.path.

Some Isaac Sim extensions ship a `pip_prebundle` directory -- an unpacked
site-packages that their `config/extension.toml` adds to the Python path. The
source tree has only the pin list (`deps/pip_*.toml`); the payload exists only
in the published package, which is why these extensions used to be taken as
prebuilts.

The wheels themselves are open source and on PyPI, so this fetches them pinned
by sha256 (`gen_pip_lock.py` writes the lock) and unpacks them into one
directory, which is all `pip_prebundle` is.

What pip would additionally do -- synthesise `bin/` wrappers for console
scripts -- is left out. Nothing in Isaac Sim runs them (the extensions import
the modules), and the ones in the published packages carry a shebang pointing
at the absolute path of NVIDIA's build machine.
"""

def _repo_root(files):
    """The repository root shared by a filegroup's files, or None if empty."""
    for f in files:
        short = f.short_path
        rel = short.split("/", 2)[2] if short.startswith("../") else short
        if f.path.endswith(rel):
            return f.path[:-len(rel)]
    return None

def _pip_prebundle_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name)

    cmds = ["set -e", 'out="%s"' % out.path, 'mkdir -p "$out"']
    inputs = []
    for wheel in ctx.attr.wheels:
        files = wheel[DefaultInfo].files.to_list()
        root = _repo_root(files)
        if not root:
            fail("%s unpacked to nothing" % wheel.label)
        inputs += files

        # -L for the same reason as everywhere else here: the inputs are
        # symlinks into their own repositories, and a directory of links into
        # other output paths is not a self-contained artifact.
        cmds.append('cp -RL "%s." "$out/"' % root)

    ctx.actions.run_shell(
        outputs = [out],
        inputs = inputs,
        command = "\n".join(cmds),
        mnemonic = "IsaacSimPipPrebundle",
        progress_message = "Unpacking %d wheels into %s" % (
            len(ctx.attr.wheels),
            ctx.label.name,
        ),
    )
    return [DefaultInfo(files = depset([out]))]

pip_prebundle = rule(
    implementation = _pip_prebundle_impl,
    attrs = {
        "wheels": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The unpacked wheels to merge, one repository each.",
        ),
    },
    doc = "Merges unpacked wheels into the site-packages an extension expects.",
)
