load("@rules_java//java/common:java_info.bzl", "JavaInfo")

def _gen_java_parser(ctx):
    outs = []
    for out_basename in ctx.attr.outs:
        out = ctx.actions.declare_file(ctx.attr.out_dir + "/" + out_basename)
        outs.append(out)
    ctx.actions.run(
        outputs = outs,
        inputs = ctx.files.src,
        executable = ctx.executable._javacc,
        arguments = [
            "-OUTPUT_DIRECTORY:" + outs[0].dirname,
            ctx.file.src.path,
        ],
        mnemonic = "Javacc",
    )
    return DefaultInfo(files = depset(outs))

gen_java_parser = rule(
    implementation = _gen_java_parser,
    attrs = {
        "_javacc": attr.label(
            default = "@javacc//:javacc",
            executable = True,
            cfg = "exec",
        ),
        "src": attr.label(
            allow_single_file = True,
        ),
        "out_dir": attr.string(),
        "outs": attr.string_list(),
    },
)

# https://github.com/javaparser/javaparser/issues/4022
def _jdk17_transition(settings, attr):
    if attr.skip_jdk_version_check:
        return {}
    setting = settings["//command_line_option:java_runtime_version"]
    if setting in ["11", "remotejdk_11", "17", "remotejdk_17"]:
        return {}
    return {"//command_line_option:java_runtime_version": "remotejdk_17"}

jdk17_transition = transition(
    implementation = _jdk17_transition,
    inputs = ["//command_line_option:java_runtime_version"],
    outputs = ["//command_line_option:java_runtime_version"],
)

def _javaparser_library(ctx):
    actual = ctx.attr.actual[0]
    return [
        actual[DefaultInfo],
        actual[JavaInfo],
        actual[OutputGroupInfo],
    ]

javaparser_library = rule(
    implementation = _javaparser_library,
    attrs = {
        "actual": attr.label(
            cfg = jdk17_transition,
            providers = [JavaInfo],
        ),
        "skip_jdk_version_check": attr.bool(),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)
