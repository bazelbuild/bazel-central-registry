"""Build helpers for the OIDN overlay."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_ispc//:ispc.bzl", "ispc_library")

def oidn_ispc_cc_library(name, out, ispc_main_source_file, srcs, defines = []):
    """Compiles an ISPC kernel and wraps the object file and header in a cc_library.

    Equivalent to ispc_cc_library from rules_ispc 0.0.6, which still uses
    native.cc_library and therefore does not work with Bazel 9.

    Args:
        name: Name of the cc_library.
        out: Name of the generated header.
        ispc_main_source_file: The .ispc file to compile.
        srcs: All .ispc and .isph files required by the kernel.
        defines: Defines for the ISPC compiler.
    """
    ispc_library(
        name = name + "_ispc_gen",
        srcs = srcs,
        out = out,
        defines = defines,
        ispc_main_source_file = ispc_main_source_file,
        # rules_ispc 0.0.6 does not declare the ISPC binary as an action input.
        tags = ["local"],
    )

    cc_library(
        name = name,
        srcs = [name + "_ispc_gen"],
        hdrs = [out],
    )

def _blob_to_cpp_impl(ctx):
    args = ctx.actions.args()
    args.add(ctx.file.src)
    args.add("-o", ctx.outputs.out_cpp)
    args.add("-H", ctx.outputs.out_h)
    args.add("-n", ctx.attr.namespace)
    ctx.actions.run(
        executable = ctx.executable._blob_to_cpp,
        arguments = [args],
        inputs = [ctx.file.src],
        outputs = [ctx.outputs.out_cpp, ctx.outputs.out_h],
        mnemonic = "OidnBlobToCpp",
        progress_message = "Generating C++ sources from %{input}",
    )

_blob_to_cpp = rule(
    implementation = _blob_to_cpp_impl,
    attrs = {
        "namespace": attr.string(mandatory = True),
        "out_cpp": attr.output(mandatory = True),
        "out_h": attr.output(mandatory = True),
        "src": attr.label(allow_single_file = True, mandatory = True),
        "_blob_to_cpp": attr.label(
            default = Label("//:blob_to_cpp"),
            cfg = "exec",
            executable = True,
        ),
    },
)

def oidn_weights_cc_library(name, weights):
    """Creates a cc_library that embeds the trained weights as C++ arrays.

    Like the CMake build, every `weights/<weight>.tza` file becomes a
    `weights/<weight>.cpp` and `weights/<weight>.h` pair which defines the array
    `oidn::blobs::weights::<weight>`.

    Args:
        name: Name of the cc_library.
        weights: Names of the weight files in weights/ (without the .tza extension).
    """
    for weight in weights:
        _blob_to_cpp(
            name = "{}_{}".format(name, weight),
            src = "weights/{}.tza".format(weight),
            out_cpp = "weights/{}.cpp".format(weight),
            out_h = "weights/{}.h".format(weight),
            namespace = "oidn::blobs::weights",
        )

    cc_library(
        name = name,
        srcs = ["weights/{}.cpp".format(weight) for weight in weights],
        hdrs = ["weights/{}.h".format(weight) for weight in weights],
    )
