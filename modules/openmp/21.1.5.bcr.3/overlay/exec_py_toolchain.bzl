"""Exposes the Python toolchain resolved for the execution platform.

`@rules_python//python:current_py_toolchain` resolves against the
configuration of the target that depends on it. A genrule generating sources
for the target platform therefore gets an interpreter built for the target
platform, which cannot be executed on the host when cross-compiling.

Depending on it through an `cfg = "exec"` attribute performs toolchain
resolution against the execution platform instead, and forwarding its
providers keeps `$(PYTHON3)` and the interpreter's runtime files usable from a
plain genrule.
"""

def _exec_py_toolchain_impl(ctx):
    py_toolchain = ctx.attr._py_toolchain
    default_info = py_toolchain[DefaultInfo]
    return [
        py_toolchain[platform_common.TemplateVariableInfo],
        DefaultInfo(
            files = default_info.files,
            runfiles = default_info.default_runfiles,
        ),
    ]

exec_py_toolchain = rule(
    implementation = _exec_py_toolchain_impl,
    doc = "Provides $(PYTHON3) for the execution platform.",
    attrs = {
        "_py_toolchain": attr.label(
            default = "@rules_python//python:current_py_toolchain",
            cfg = "exec",
        ),
    },
)
