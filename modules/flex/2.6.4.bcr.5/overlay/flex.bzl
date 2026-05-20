"""Rule for running GNU Flex with M4 configured automatically."""

def _collect_tool_files(target):
    """Collect files and default runfiles from a target into a depset for tools."""
    info = target[DefaultInfo]
    transitive = [info.files]
    if info.default_runfiles:
        transitive.append(info.default_runfiles.files)
    return depset(transitive = transitive)

def _flex_impl(ctx):
    tool = ctx.executable.flex
    m4 = ctx.file.m4

    env = {
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

    tools = _collect_tool_files(ctx.attr.m4)

    ctx.actions.run(
        executable = tool,
        arguments = [args],
        inputs = ctx.files.srcs,
        tools = tools,
        outputs = ctx.outputs.outs,
        mnemonic = "Flex",
        env = env,
    )

    return [DefaultInfo(files = depset(ctx.outputs.outs))]

flex = rule(
    doc = """\
Runs GNU Flex on a scanner specification to produce lexer source.

This rule configures the `M4` environment variable automatically. The
interface follows the same pattern as `bazel_skylib`'s `run_binary`:
provide `srcs`, `outs`, and `args` with `$(execpath ...)` expansions for
input and output paths.

The m4 binary can be overridden globally via the `//:m4` label_flag,
or per-target via the `m4` attr.

Example:
    load("@flex//:flex.bzl", "flex")

    flex(
        name = "scanner",
        srcs = ["scanner.l"],
        outs = ["scanner.c"],
        args = ["-o", "$(execpath scanner.c)", "$(execpath scanner.l)"],
    )
""",
    implementation = _flex_impl,
    attrs = {
        "args": attr.string_list(
            doc = "Arguments to pass to flex. Supports $(execpath ...) for input and output paths.",
            mandatory = True,
        ),
        "flex": attr.label(
            doc = "The flex binary to use.",
            default = Label("//:flex"),
            cfg = "exec",
            executable = True,
        ),
        "m4": attr.label(
            doc = "The m4 binary to use. Override globally with --@flex//:m4=<label>.",
            default = Label("//:m4"),
            cfg = "exec",
            allow_single_file = True,
        ),
        "outs": attr.output_list(
            doc = "Output files produced by flex.",
            mandatory = True,
        ),
        "srcs": attr.label_list(
            doc = "Source files (scanner specs) to provide to flex.",
            allow_files = True,
            mandatory = True,
        ),
    },
)
