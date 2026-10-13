"""Rules for building the MLX Metal kernels with the Xcode Metal toolchain."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

_EXECUTION_REQUIREMENTS = {
    "requires-darwin": "",
    "supports-xcode-requirements-set": "",
}

_METAL_FLAGS = [
    "-x",
    "metal",
    "-Wall",
    "-Wextra",
    "-fno-fast-math",
    "-Wno-c++17-extensions",
    "-Wno-c++20-extensions",
    "-Wmetal-addr-spaces",
]

def _source_root(f):
    return f.owner.workspace_root or "."

def _metal_library_impl(ctx):
    version_min = "-mmacosx-version-min=" + ctx.attr.macos_version_min[BuildSettingInfo].value
    hdrs = depset(transitive = [h.files for h in ctx.attr.hdrs])
    airs = []
    for src in ctx.files.srcs:
        air = ctx.actions.declare_file("_air/{}/{}.air".format(ctx.label.name, src.basename[:-len(".metal")]))
        args = ctx.actions.args()
        args.add_all(["-sdk", "macosx", "metal"])
        args.add_all(_METAL_FLAGS)
        args.add(version_min)
        args.add("-I" + _source_root(src))
        args.add("-c", src)
        args.add("-o", air)
        ctx.actions.run(
            executable = "/usr/bin/xcrun",
            arguments = [args],
            inputs = depset([src], transitive = [hdrs]),
            outputs = [air],
            mnemonic = "MetalCompile",
            progress_message = "Compiling Metal kernel %{input}",
            execution_requirements = _EXECUTION_REQUIREMENTS,
            use_default_shell_env = True,
        )
        airs.append(air)

    args = ctx.actions.args()
    args.add_all(["-sdk", "macosx", "metal"])
    args.add(version_min)
    args.add_all(airs)
    args.add("-o", ctx.outputs.out)
    ctx.actions.run(
        executable = "/usr/bin/xcrun",
        arguments = [args],
        inputs = airs,
        outputs = [ctx.outputs.out],
        mnemonic = "MetalLink",
        progress_message = "Linking %{output}",
        execution_requirements = _EXECUTION_REQUIREMENTS,
        use_default_shell_env = True,
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

metal_library = rule(
    implementation = _metal_library_impl,
    doc = "Compiles .metal sources into a .metallib using `xcrun metal`.",
    attrs = {
        "hdrs": attr.label_list(allow_files = True),
        "macos_version_min": attr.label(mandatory = True, providers = [BuildSettingInfo]),
        "out": attr.output(mandatory = True),
        "srcs": attr.label_list(allow_files = [".metal"], mandatory = True),
    },
)

def _metal_jit_source_impl(ctx):
    src = ctx.file.src
    root = _source_root(src)
    path = src.path[len(src.owner.workspace_root) + 1:] if src.owner.workspace_root else src.path
    prefix = "mlx/backend/metal/kernels/"
    if not path.startswith(prefix) or not path.endswith(".h"):
        fail("src must be a header under mlx/backend/metal/kernels/")
    kernel = path[len(prefix):-len(".h")]
    if ctx.outputs.out.basename != kernel.split("/")[-1] + ".cpp":
        fail("out must be named {}.cpp".format(kernel.split("/")[-1]))

    hdrs = depset(transitive = [h.files for h in ctx.attr.hdrs])
    ctx.actions.run(
        executable = "/bin/bash",
        arguments = [
            ctx.file.script.path,
            ctx.outputs.out.dirname,
            "unused",
            root,
            kernel,
            "-mmacosx-version-min=" + ctx.attr.macos_version_min[BuildSettingInfo].value,
        ],
        inputs = depset([src, ctx.file.script], transitive = [hdrs]),
        outputs = [ctx.outputs.out],
        mnemonic = "MetalJitSource",
        progress_message = "Generating Metal JIT source %{output}",
        execution_requirements = _EXECUTION_REQUIREMENTS,
        use_default_shell_env = True,
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

metal_jit_source = rule(
    implementation = _metal_jit_source_impl,
    doc = "Embeds a preprocessed Metal header as a C++ string (make_compiled_preamble.sh).",
    attrs = {
        "hdrs": attr.label_list(allow_files = True),
        "macos_version_min": attr.label(mandatory = True, providers = [BuildSettingInfo]),
        "out": attr.output(mandatory = True),
        "script": attr.label(allow_single_file = True, mandatory = True),
        "src": attr.label(allow_single_file = [".h"], mandatory = True),
    },
)
