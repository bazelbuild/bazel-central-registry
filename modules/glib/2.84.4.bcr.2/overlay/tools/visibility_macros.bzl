"""Generate GLib visibility headers with the execution Python toolchain."""

_PYTHON_TOOLCHAIN = "@rules_python//python:toolchain_type"

def _visibility_macros_impl(ctx):
    # Run the generator with the exec-configured Python interpreter rather than
    # through a py_binary: rules_python's launcher needs a host python3 (default
    # bootstrap) or Bash (script bootstrap) to start, which breaks consumers that
    # run actions with an empty PATH and no host tools. Calling the interpreter
    # directly on the script needs neither, on Linux, macOS and Windows.
    runtime = ctx.toolchains[_PYTHON_TOOLCHAIN].py3_runtime
    out = ctx.outputs.outs[0]
    src = ctx.file.src
    args = ctx.actions.args()
    args.add(ctx.file._script)
    for arg in ctx.attr.arguments:
        args.add(arg.format(src = src.path if src else "", out = out.path))
    ctx.actions.run(
        executable = runtime.interpreter or runtime.interpreter_path,
        inputs = depset([ctx.file._script] + ([src] if src else []), transitive = [runtime.files] if runtime.files else []),
        arguments = [args],
        outputs = [out],
        mnemonic = "GLibVisibilityMacros",
        env = {"PYTHONHASHSEED": "0"},
    )
    return DefaultInfo(files = depset([out]))

visibility_macros = rule(
    implementation = _visibility_macros_impl,
    attrs = {
        "arguments": attr.string_list(),
        "outs": attr.output_list(mandatory = True),
        "src": attr.label(allow_single_file = True),
        "_script": attr.label(default = "//tools:gen-visibility-macros.py", allow_single_file = True),
    },
    toolchains = [_PYTHON_TOOLCHAIN],
)
