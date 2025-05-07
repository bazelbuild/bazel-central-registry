def transition_to_bootstrap_impl(settings, attr):
    return {"@cpython//:cpython_bootstrap": True}

transition_to_bootstrap = transition(
    implementation = transition_to_bootstrap_impl,
    inputs = [],
    outputs = ["@cpython//:cpython_bootstrap"],
)

def symlink_to_bootstrap_impl(ctx):
    ctx.actions.symlink(
        output = ctx.outputs.executable,
        target_file = ctx.executable.target,
    )

    default_info = DefaultInfo(
        files = depset([ctx.outputs.executable]),
        default_runfiles = ctx.runfiles([ctx.outputs.executable], collect_default = True).merge(ctx.attr.target[DefaultInfo].default_runfiles),
        data_runfiles = ctx.runfiles([ctx.outputs.executable], collect_data = True).merge(ctx.attr.target[DefaultInfo].data_runfiles),
    )
    return [default_info]

symlink_to_bootstrap = rule(
    implementation = symlink_to_bootstrap_impl,
    attrs = {
        "target": attr.label(executable = True, cfg = "target"),
    },
    cfg = transition_to_bootstrap,
    executable = True,
)

def bootstrap_py_binary(name, **kwargs):
    native.py_binary(
        name = name + "_bootstrap",
        **kwargs
    )

    symlink_to_bootstrap(
        name = name,
        target = name + "_bootstrap",
    )


def external_prefix():
    repo_name = native.repository_name()
    if repo_name == "@":
        return ""
    else:
        return "external/" + repo_name[1:] + "/"
