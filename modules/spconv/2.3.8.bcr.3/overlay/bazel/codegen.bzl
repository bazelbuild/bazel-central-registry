"""Execution-phase spconv inference generation with individually declared files."""

load(":outputs.bzl", "OUTPUTS")

def _codegen_impl(ctx):
    files = {path: ctx.actions.declare_file(ctx.label.name + "/" + path) for path in OUTPUTS}
    args = ctx.actions.args()
    args.add("--output", files["include/spconvlib/spconv/csrc/sparse/all/SpconvOps.h"].path.removesuffix("/include/spconvlib/spconv/csrc/sparse/all/SpconvOps.h"))
    args.add("--manifest", ctx.file.manifest)
    ctx.actions.run(
        executable = ctx.attr.tool[DefaultInfo].files_to_run,
        arguments = [args],
        inputs = [ctx.file.manifest],
        outputs = files.values(),
        mnemonic = "SpconvCodegen",
        progress_message = "Generating spconv inference kernels (CUDA 12.8 / SM89)",
        env = {
            "CUMM_BAZEL_CODEGEN": "1",
            "CUMM_CUDA_ARCH_LIST": "8.9",
            "CUMM_CUDA_VERSION": "12.8",
            "CUMM_DISABLE_JIT": "1",
            "SPCONV_DISABLE_JIT": "1",
            "PYTHONNOUSERSITE": "1",
            "PYTHONHASHSEED": "0",
            "LC_ALL": "C",
        },
        use_default_shell_env = False,
    )
    return [
        DefaultInfo(files = depset(files.values())),
        OutputGroupInfo(
            headers = depset([f for path, f in files.items() if path.startswith("include/")]),
            cc = depset([f for path, f in files.items() if path.endswith(".cc")]),
            cuda = depset([f for path, f in files.items() if path.endswith(".cu")]),
        ),
    ]

spconv_codegen = rule(
    implementation = _codegen_impl,
    attrs = {
        "manifest": attr.label(default = "//bazel:outputs.bzl", allow_single_file = True),
        "tool": attr.label(default = "//bazel:generate", executable = True, cfg = "exec"),
    },
)
