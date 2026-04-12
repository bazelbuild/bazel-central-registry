"""Rules and macros for building GMP with Bazel."""

def _gmp_gen_impl(ctx):
    args = [ctx.outputs.out.path, ctx.executable.tool.path] + ctx.attr.args
    ctx.actions.run(
        outputs = [ctx.outputs.out],
        inputs = [],
        executable = ctx.executable._redirect,
        arguments = args,
        tools = [ctx.executable.tool],
        mnemonic = "GmpGen",
        progress_message = "Generating %s" % ctx.outputs.out.short_path,
    )

    return [DefaultInfo(
        files = depset([ctx.outputs.out]),
    )]

gmp_gen = rule(
    implementation = _gmp_gen_impl,
    attrs = {
        "args": attr.string_list(
            doc = "Additional command-line arguments passed to the generator tool.",
            default = [],
        ),
        "out": attr.output(
            doc = "The output file to generate. The tool's stdout is captured into this file.",
            mandatory = True,
        ),
        "tool": attr.label(
            doc = "The GMP generator tool (e.g. gen-fac, gen-fib) whose stdout produces the output.",
            mandatory = True,
            executable = True,
            cfg = "exec",
        ),
        "_redirect": attr.label(
            default = Label("//bazel:redirect_stdout"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def _gmp_copy_impl(ctx):
    ctx.actions.symlink(
        output = ctx.outputs.out,
        target_file = ctx.file.src,
    )

    return [DefaultInfo(
        files = depset([ctx.outputs.out]),
    )]

gmp_copy = rule(
    doc = "Creates a symlink to place a source file at a specific path in the output tree.",
    implementation = _gmp_copy_impl,
    attrs = {
        "out": attr.output(
            doc = "The output path for the symlink.",
            mandatory = True,
        ),
        "src": attr.label(
            doc = "The source file to symlink.",
            mandatory = True,
            allow_single_file = True,
        ),
    },
)

def _gmp_mpn_op_impl(ctx):
    """Generates a wrapper .c file that defines OPERATION_xxx and includes the source."""
    out = ctx.actions.declare_file(ctx.attr.operation + ".c")
    ctx.actions.write(
        output = out,
        content = "#define OPERATION_{op} 1\n#include \"{src}\"\n".format(
            op = ctx.attr.operation,
            src = ctx.attr.src,
        ),
    )
    return [DefaultInfo(files = depset([out]))]

_gmp_mpn_op = rule(
    doc = "Generates a wrapper .c file that `#define`s `OPERATION_<name>` and `#include`s a multi-function MPN source.",
    implementation = _gmp_mpn_op_impl,
    attrs = {
        "operation": attr.string(
            doc = "The MPN operation name (e.g. `iand_n`). Used to define `OPERATION_<name>` in the wrapper.",
            mandatory = True,
        ),
        "src": attr.string(
            doc = "Path to the multi-function MPN source file to `#include` (e.g. `mpn/generic/logops_n.c`).",
            mandatory = True,
        ),
    },
)

def gmp_mpn_multi(*, name, src, operations):
    """Generates wrapper sources for a multi-function MPN source file.

    Some mpn/generic files (e.g. logops_n.c) produce multiple functions
    selected by -DOPERATION_xxx. This macro generates a tiny .c wrapper
    per operation so they can all be compiled within the main cc_library.

    Args:
        name: The name of the collection target.
        src: The path to the multi-function MPN source file (e.g. `mpn/generic/logops_n.c`).
        operations: List of operation names to generate wrappers for (e.g. `["iand_n", "ior_n", "ixor_n"]`).

    Returns:
        The list of generated source labels.
    """
    targets = []
    for op in operations:
        tgt = "_mpn_" + op
        _gmp_mpn_op(
            name = tgt,
            operation = op,
            src = src,
        )
        targets.append(":" + tgt)

    native.filegroup(
        name = name,
        srcs = targets,
    )

    return targets
