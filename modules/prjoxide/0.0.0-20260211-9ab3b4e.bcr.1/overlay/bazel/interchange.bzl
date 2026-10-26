"""Transition rule that forces `//:interchange=True` for its `actual` dep."""

_FLAG = str(Label("//:interchange"))

def _interchange_on_impl(_settings, _attr):
    return {_FLAG: True}

_interchange_on = transition(
    implementation = _interchange_on_impl,
    inputs = [],
    outputs = [_FLAG],
)

def _interchange_transition_impl(ctx):
    src = ctx.attr.actual[0]
    src_default = src[DefaultInfo]
    if src_default.files_to_run and src_default.files_to_run.executable:
        # Republish the binary under our own name so it appears in the package's
        # output namespace (Bazel forbids two targets producing the same path).
        out = ctx.actions.declare_file(ctx.label.name)
        ctx.actions.symlink(
            output = out,
            target_file = src_default.files_to_run.executable,
            is_executable = True,
        )
        return [DefaultInfo(
            executable = out,
            runfiles = src_default.default_runfiles,
        )]
    return [src_default]

interchange_transition = rule(
    implementation = _interchange_transition_impl,
    doc = "Re-expose a target with `//:interchange=True` baked in.",
    attrs = {
        "actual": attr.label(
            cfg = _interchange_on,
            mandatory = True,
            doc = "Target to transition. Typically an executable alias.",
        ),
    },
    executable = True,
)
