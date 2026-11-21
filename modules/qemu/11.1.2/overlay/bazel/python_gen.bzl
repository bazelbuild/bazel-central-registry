"""Invoke a generator with the exec-platform Python runtime, not a launcher."""

load("@rules_python//python:py_runtime_info.bzl", "PyRuntimeInfo")

def _python_gen_impl(ctx):
    runtime = ctx.attr._python[PyRuntimeInfo]

    # Reject platform runtimes: an action must declare the interpreter and
    # standard library as inputs, even if a consumer selects its own toolchain.
    if runtime.interpreter == None:
        fail("QEMU generators need a file-backed Python toolchain")
    args = ctx.actions.args()
    outs = ctx.outputs.outs
    if ctx.attr.capture_stdout:
        if len(outs) != 1:
            fail("capture_stdout needs exactly one output")
        args.add(ctx.file._capture)
        args.add(outs[0])
    args.add(ctx.file.script)
    for arg in ctx.attr.arguments:
        if arg == "{inputs}":
            args.add_all(ctx.files.srcs)
        else:
            args.add(arg.format(
                out = outs[0].path,
                out_dir = outs[0].dirname,
                src = ctx.file.src.path if ctx.file.src else "",
            ))
    ctx.actions.run(
        executable = runtime.interpreter,
        arguments = [args],
        inputs = depset(
            [ctx.file.script] + ctx.files.srcs + ctx.files.deps +
            ([ctx.file.src] if ctx.file.src else []) +
            ([ctx.file._capture] if ctx.attr.capture_stdout else []),
            transitive = [runtime.files],
        ),
        outputs = outs,
        env = {
            "LC_ALL": "C",
            "PATH": "/nonexistent",
            "PYTHONDONTWRITEBYTECODE": "1",
            "PYTHONHASHSEED": "0",
        },
        mnemonic = "QemuPythonGen",
    )
    return DefaultInfo(files = depset(outs))

python_gen = rule(
    implementation = _python_gen_impl,
    attrs = {
        "arguments": attr.string_list(),
        "capture_stdout": attr.bool(),
        "deps": attr.label_list(allow_files = True),
        "outs": attr.output_list(mandatory = True),
        "script": attr.label(allow_single_file = True, mandatory = True),
        "src": attr.label(allow_single_file = True),
        "srcs": attr.label_list(allow_files = True),
        "_capture": attr.label(default = Label("//bazel:capture_stdout.py"), allow_single_file = True),
        "_python": attr.label(
            default = Label("@python_3_12//:py3_runtime"),
            cfg = "exec",
            providers = [PyRuntimeInfo],
        ),
    },
)
