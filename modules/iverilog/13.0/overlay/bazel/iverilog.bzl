"""Custom rules for the iverilog build."""

load("@rules_cc//cc:cc_test.bzl", "cc_test")

# =============================================================================
# Shared compiler/linker flags used across all iverilog packages
# =============================================================================

SHARED_LINKOPTS = select({
    "@platforms//os:macos": [
        "-undefined",
        "dynamic_lookup",
    ],
    "//conditions:default": [],
})

PLUGIN_HOST_LINKOPTS = select({
    "@platforms//os:linux": [
        "-rdynamic",
        "-ldl",
    ],
    "@platforms//os:macos": [],
    "@platforms//os:windows": [],
    "//conditions:default": ["-ldl"],
})

WARNING_COPTS = select({
    "@rules_cc//cc/compiler:msvc-cl": ["/w", "/DYY_NO_UNISTD_H"],
    "//conditions:default": ["-w"],
})

# MSVC defaults to C++14 which is a superset of C++11.
# /Zc:__cplusplus makes MSVC report the actual C++ standard version
# in the __cplusplus macro (default is 199711L for compat), which
# prevents upstream guards like `#if __cplusplus < 201103L` from
# incorrectly aliasing unique_ptr to auto_ptr.
CXX_STD = select({
    "@rules_cc//cc/compiler:msvc-cl": ["/Zc:__cplusplus"],
    "//conditions:default": ["-std=c++11"],
})

# Position-independent code flag. A no-op on Windows where all code
# in DLLs is position-independent by default.
PICFLAG = select({
    "@rules_cc//cc/compiler:msvc-cl": [],
    "//conditions:default": ["-fPIC"],
})

# Math library. MSVC links math functions from the CRT automatically.
MATH_LINKOPTS = select({
    "@rules_cc//cc/compiler:msvc-cl": [],
    "//conditions:default": ["-lm"],
})

def _draw_tt_impl(ctx):
    args = ctx.actions.args()
    args.add(ctx.outputs.out)
    args.add("--")
    args.add(ctx.executable._tool)

    ctx.actions.run(
        outputs = [ctx.outputs.out],
        executable = ctx.executable._redirector,
        arguments = [args],
        tools = [ctx.executable._tool],
        mnemonic = "DrawTT",
    )

    return [DefaultInfo(
        files = depset([ctx.outputs.out]),
    )]

def iverilog_smoke_test(*, name, binaries, ivl_base, **kwargs):
    """Smoke test that verifies iverilog binaries are functional.

    Args:
        name: Name of the test target.
        binaries: List of binary targets to test.
        ivl_base: ivl_base target providing the IVL base directory.
        **kwargs: Additional arguments passed to cc_test.
    """
    cc_test(
        name = name,
        srcs = [Label("//bazel:iverilog_smoke_test.cc")],
        args = ["$(rlocationpath {})".format(b) for b in binaries],
        data = binaries + [ivl_base],
        env = {"IVL_BASE_RLOCATIONPATH": "$(rlocationpath {})".format(ivl_base)},
        deps = ["@rules_cc//cc/runfiles"],
        **kwargs
    )

def _ivl_base_impl(ctx):
    base_dir = ctx.actions.declare_directory(ctx.label.name)

    args = ctx.actions.args()
    args.add(base_dir.path)
    args.add("--")

    inputs = []
    for target, dest_name in ctx.attr.files.items():
        files = target.files.to_list()
        if len(files) != 1:
            fail("ivl_base: label %s must produce exactly one file, got %d" % (
                target.label,
                len(files),
            ))
        f = files[0]
        args.add("%s=%s" % (dest_name, f.path))
        inputs.append(f)

    ctx.actions.run(
        outputs = [base_dir],
        inputs = inputs,
        executable = ctx.executable._tool,
        arguments = [args],
        mnemonic = "IvlBase",
    )

    return [DefaultInfo(files = depset([base_dir]))]

ivl_base = rule(
    doc = """Assembles an IVL base directory from individual components.

    The iverilog driver expects a flat directory containing all its
    components (ivl, ivlpp, *.tgt, *.vpi, *.conf, include/).  This rule
    copies all specified files into a single tree artifact with the
    destination filenames given in the ``files`` dict.  This handles
    renaming (e.g. ``libvvp_tgt.so`` to ``vvp.tgt``).
    """,
    implementation = _ivl_base_impl,
    attrs = {
        "files": attr.label_keyed_string_dict(
            doc = "Map of source label to destination filename in the base directory.",
            allow_files = True,
        ),
        "_tool": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("//bazel:ivl_base_tool"),
        ),
    },
)

draw_tt = rule(
    doc = "Generates VVP truth tables by running the draw_tt tool and capturing its stdout.",
    implementation = _draw_tt_impl,
    attrs = {
        "out": attr.output(
            doc = "The output file to write the generated tables to.",
            mandatory = True,
        ),
        "_redirector": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("//bazel:stdout_to_file"),
        ),
        "_tool": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("//vvp:draw_tt"),
        ),
    },
)
