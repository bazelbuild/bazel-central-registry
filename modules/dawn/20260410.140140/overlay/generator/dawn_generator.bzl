def _quote(value):
    return "'{}'".format(value.replace("'", "'\"'\"'"))

def _package_relative_outputs(outputs):
    package_name = native.package_name()
    if not package_name:
        return outputs

    prefix = package_name + "/"
    package_outputs = []
    for output in outputs:
        if not output.startswith(prefix):
            fail("output {} must start with {}".format(output, prefix))
        package_outputs.append(output[len(prefix):])
    return package_outputs

def _dirname(path):
    parts = path.split("/")
    if len(parts) <= 1:
        return ""
    return "/".join(parts[:-1])

def _expand_value(ctx, value):
    dirname_prefix = "$$(dirname $(location "
    dirname_suffix = "))"
    if value.startswith(dirname_prefix) and value.endswith(dirname_suffix):
        label = value[len(dirname_prefix):-len(dirname_suffix)]
        return _dirname(ctx.expand_location("$(location {})".format(label), targets = ctx.attr.srcs))
    return ctx.expand_location(value, targets = ctx.attr.srcs)

def _expand_args(ctx, values):
    expanded = []
    for value in values:
        expanded.append(_expand_value(ctx, value))
    return expanded

def _output_root_dir(out, package_path, package_relative):
    if package_relative or not package_path:
        return out.dirname
    package_depth = len(package_path.split("/"))
    parts = out.dirname.split("/")
    return "/".join(parts[:-package_depth])

def _dawn_python_generator_impl(ctx):
    output_dir = _output_root_dir(
        ctx.outputs.outs[0],
        ctx.attr.package_path,
        ctx.attr.package_relative,
    )
    args = [
        "--template-dir",
        ctx.file.template_anchor.dirname,
        "--output-dir",
        output_dir,
    ]
    for output in ctx.attr.output_filters:
        args += ["--output-filter", output]
    args += _expand_args(ctx, ctx.attr.args)

    ctx.actions.run(
        executable = ctx.executable.script,
        inputs = depset(
            direct = ctx.files.srcs + [ctx.file.template_anchor],
            transitive = [depset(ctx.files.templates)]
        ),
        outputs = ctx.outputs.outs,
        arguments = args,
        tools = [ctx.executable.script],
        mnemonic = "DawnPythonGenerator",
        progress_message = "Generating Dawn sources for {}".format(ctx.label.name)
    )

dawn_python_generator_rule = rule(
    implementation = _dawn_python_generator_impl,
    attrs = {
        "args": attr.string_list(),
        "outs": attr.output_list(mandatory = True),
        "output_filters": attr.string_list(),
        "script": attr.label(
            executable = True,
            cfg = "exec",
            mandatory = True
        ),
        "srcs": attr.label_list(
            allow_files = True
        ),
        "package_path": attr.string(),
        "package_relative": attr.bool(),
        "template_anchor": attr.label(
            allow_single_file = True,
            mandatory = True
        ),
        "templates": attr.label(
            allow_files = True,
            mandatory = True
        )
    }
)

def dawn_python_generator(name, script, outputs, args = [], extra_inputs = [], visibility = None, package_relative = False):
    dawn_python_generator_rule(
        name = name,
        srcs = extra_inputs,
        outs = _package_relative_outputs(outputs),
        args = args,
        output_filters = outputs,
        package_path = native.package_name(),
        package_relative = package_relative,
        script = script,
        template_anchor = "//generator:template_anchor",
        templates = "//generator:templates",
        visibility = visibility
    )

def dawn_json_generator(name, target, outputs, extra_inputs = [], extra_args = [], visibility = None, package_relative = False):
    args = [
        "--dawn-json",
        "$(location //src/dawn:dawn.json)",
        "--wire-json",
        "$(location //src/dawn:dawn_wire.json)",
        "--kotlin-json",
        "$(location //src/dawn:dawn_kotlin.json)",
        "--targets",
        target,
        "--webgpu-kt-docs",
        "$(location //src/dawn:webgpu_kt_docs.json)",
    ] + extra_args
    dawn_python_generator(
        name = name,
        script = "//generator:dawn_json_generator_bin",
        outputs = outputs,
        args = args,
        extra_inputs = extra_inputs + [
            "//src/dawn:dawn.json",
            "//src/dawn:dawn_wire.json",
            "//src/dawn:dawn_kotlin.json",
            "//src/dawn:webgpu_kt_docs.json",
            "@webgpu_headers//:webgpu_json"
        ],
        package_relative = package_relative,
        visibility = visibility
    )
