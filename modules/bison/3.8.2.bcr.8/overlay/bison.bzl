"""Rule for running GNU Bison with M4 and PKGDATADIR configured automatically."""

def _collect_tool_files(target):
    """Collect files and default runfiles from a target into a depset for tools."""
    info = target[DefaultInfo]
    transitive = [info.files]
    if info.default_runfiles:
        transitive.append(info.default_runfiles.files)
    return depset(transitive = transitive)

def _resolve_pkgdatadir(files):
    """Derive the bison PKGDATADIR path from the provided files.

    If the label resolves to a single directory (TreeArtifact), its path is
    used directly.  Otherwise, a file within the data tree is located and its
    path is truncated at the ``data`` component.
    """
    if len(files) == 1 and files[0].is_directory:
        return files[0].path
    for f in files:
        idx = f.path.find("/data/")
        if idx >= 0:
            return f.path[:idx + 5]
        if f.path.startswith("data/"):
            return "data"
    fail("Could not determine BISON_PKGDATADIR: no 'data' directory found in provided files")

def _bison_impl(ctx):
    tool = ctx.executable.bison
    m4 = ctx.file.m4
    pkgdatadir = _resolve_pkgdatadir(ctx.files.bison_pkgdatadir)

    env = {
        "BISON_PKGDATADIR": pkgdatadir,
        "M4": m4.path,
    }

    out_map = {}
    for file, label in zip(ctx.outputs.outs, ctx.attr.outs):
        _, _, relative = str(label).partition("//")
        out_map["$(execpath {})".format(label)] = file
        out_map["$(execpath {})".format(relative)] = file

    args = ctx.actions.args()
    for arg in ctx.attr.args:
        if arg in out_map:
            args.add(out_map[arg])
        else:
            args.add(ctx.expand_location(arg, ctx.attr.srcs))

    tools = depset(transitive = [
        _collect_tool_files(ctx.attr.m4),
        _collect_tool_files(ctx.attr.bison_pkgdatadir),
    ])

    ctx.actions.run(
        executable = tool,
        arguments = [args],
        inputs = ctx.files.srcs,
        tools = tools,
        outputs = ctx.outputs.outs,
        mnemonic = "Bison",
        env = env,
    )

    return [DefaultInfo(files = depset(ctx.outputs.outs))]

bison = rule(
    doc = """\
Runs GNU Bison on a grammar file to produce parser source and optionally a header.

This rule configures `BISON_PKGDATADIR` and `M4` environment variables
automatically. The interface follows the same pattern as `bazel_skylib`'s
`run_binary`: provide `srcs`, `outs`, and `args` with `$(execpath ...)`
expansions for input and output paths.

The m4 binary and bison data directory can be overridden globally via the
`//:m4` and `//:bison_pkgdatadir` label_flags, or per-target via the `m4`
and `bison_pkgdatadir` attrs.

Example:
    load("@bison//:bison.bzl", "bison")

    bison(
        name = "parser",
        srcs = ["parser.y"],
        outs = ["parser.c", "parser.h"],
        args = ["-o", "$(execpath parser.c)", "-d", "$(execpath parser.y)"],
    )
""",
    implementation = _bison_impl,
    attrs = {
        "args": attr.string_list(
            doc = "Arguments to pass to bison. Supports $(execpath ...) for input and output paths.",
            mandatory = True,
        ),
        "bison": attr.label(
            doc = "The bison binary to use.",
            default = Label("//:bison"),
            cfg = "exec",
            executable = True,
        ),
        "bison_pkgdatadir": attr.label(
            doc = """\
Bison's data directory (containing m4sugar, skeletons, etc.).  If this
resolves to a single directory, it is used directly.  If it resolves to
files, the path is truncated at the `data` component.  Override globally
with --@bison//:bison_pkgdatadir=<label>.""",
            default = Label("//:bison_pkgdatadir"),
            allow_files = True,
        ),
        "m4": attr.label(
            doc = "The m4 binary to use. Override globally with --@bison//:m4=<label>.",
            default = Label("//:m4"),
            cfg = "exec",
            allow_single_file = True,
        ),
        "outs": attr.output_list(
            doc = "Output files produced by bison.",
            mandatory = True,
        ),
        "srcs": attr.label_list(
            doc = "Source files (grammars) to provide to bison.",
            allow_files = True,
            mandatory = True,
        ),
    },
)
