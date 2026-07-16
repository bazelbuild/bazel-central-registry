"""Macro for wiring up flex scanner tests."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

def _run_flex_impl(ctx):
    m4 = None
    for file in ctx.attr.flex[DefaultInfo].default_runfiles.files.to_list():
        if file.basename in ["m4", "m4.exe"]:
            m4 = file
            break

    if not m4:
        fail("Failed to find m4 binary in runfiles of {}".format(ctx.attr.flex.label))

    args = ctx.actions.args()
    args.add("-o", ctx.outputs.out)
    args.add(ctx.file.src)

    ctx.actions.run(
        mnemonic = "FlexRun",
        executable = ctx.executable.flex,
        arguments = [args],
        outputs = [ctx.outputs.out],
        inputs = [ctx.file.src],
        tools = [m4],
        env = {
            "M4": m4.path,
        },
    )

    return [DefaultInfo(
        files = depset([ctx.outputs.out]),
    )]

run_flex = rule(
    doc = "An internal rule for testing flex executions.",
    implementation = _run_flex_impl,
    attrs = {
        "flex": attr.label(
            doc = "The flex binary.",
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "out": attr.output(
            doc = "The output file",
            mandatory = True,
        ),
        "src": attr.label(
            doc = "The source file",
            allow_single_file = True,
            mandatory = True,
        ),
    },
)

def flex_test(name, src, input):
    """Build a scanner from a .l file and test it with stdin input.

    Mirrors the native test suite pattern:
        flex -o scanner.c scanner.l
        cc -DHAVE_CONFIG_H scanner.c -o scanner
        ./scanner < scanner.txt

    Args:
        name: Base name for the test (targets: gen_{name}, {name}_bin, test_{name}).
        src: The .l flex input file.
        input: The .txt file to pipe to stdin.
    """
    gen_name = "gen_" + name
    bin_name = name + "_bin"
    out_file = name + "_gen.c"

    run_flex(
        name = gen_name,
        src = src,
        out = out_file,
        testonly = True,
        flex = ":flex",
    )

    cc_binary(
        name = bin_name,
        srcs = [":" + gen_name],
        copts = ["-DHAVE_CONFIG_H"] + select({
            "@platforms//os:windows": ["-DYY_NO_UNISTD_H"],
            "//conditions:default": [],
        }),
        deps = [":config"],
        testonly = True,
    )

    cc_test(
        name = "test_" + name,
        srcs = ["test_runner.cc"],
        data = [
            ":" + bin_name,
            input,
        ],
        args = [
            "$(rlocationpath :" + bin_name + ")",
            "$(rlocationpath " + input + ")",
        ],
        deps = ["@rules_cc//cc/runfiles"],
    )
