"""Assembling libffi's .S sources with the MSVC toolchain.

Neither of Microsoft's assemblers preprocesses, so upstream's msvcc.sh runs
the source through cl first and hands the result to ml64 or armasm64:

    cl -nologo -EP $includes $defines $src > $ppsrc
    ml64 -nologo $output $ppsrc          # or: armasm64 -nologo -o $output $ppsrc

Bazel's own assemble action cannot stand in for that.  It feeds the .S
straight to the assembler, and on arm64 Windows there is no assembler wired
up at all -- windows_cc_configure.bzl lists no ML tool for that target and
leaves the path as the literal string
"msvc_arm_toolchain_does_not_support_ml".

So do both steps here and hand cc_library a plain .obj.  The assembler is
located next to cl.exe, which is where MSVC keeps it: every tool for a given
host/target pair lives in the same bin directory.
"""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")

def _sibling(tool_path, name):
    """The path to `name` in the directory holding `tool_path`."""
    cut = max(tool_path.rfind("/"), tool_path.rfind("\\"))
    return tool_path[:cut + 1] + name

def _msvc_assemble_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    compiler = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.c_compile,
    )

    # INCLUDE matters here beyond libffi's own headers: win64_armasm.S pulls
    # in the SDK's ksarm64.h for its unwind macros.
    env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.c_compile,
        variables = cc_common.create_compile_variables(
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
        ),
    )

    compilation_context = cc_common.merge_compilation_contexts(
        compilation_contexts = [dep[CcInfo].compilation_context for dep in ctx.attr.deps],
    )

    preprocessed = ctx.actions.declare_file(ctx.label.name + ".asm")
    preprocess_args = ctx.actions.args()

    # /P writes the preprocessed source to a file, /EP drops the #line
    # directives that the assemblers would choke on; together they are
    # msvcc.sh's "-EP > $ppsrc" without needing a shell to redirect.
    preprocess_args.add("/nologo")
    preprocess_args.add("/P")
    preprocess_args.add("/EP")
    preprocess_args.add(preprocessed, format = "/Fi%s")
    preprocess_args.add_all(compilation_context.includes, format_each = "/I%s")
    preprocess_args.add_all(compilation_context.quote_includes, format_each = "/I%s")
    preprocess_args.add_all(compilation_context.system_includes, format_each = "/I%s")
    preprocess_args.add_all(compilation_context.defines, format_each = "/D%s")
    preprocess_args.add(ctx.file.src)

    ctx.actions.run(
        outputs = [preprocessed],
        inputs = depset(
            direct = [ctx.file.src],
            transitive = [compilation_context.headers, cc_toolchain.all_files],
        ),
        executable = compiler,
        arguments = [preprocess_args],
        env = env,
        mnemonic = "MsvcPreprocessAsm",
        progress_message = "Preprocessing %s for the MSVC assembler" % ctx.file.src.short_path,
    )

    obj = ctx.actions.declare_file(ctx.label.name + ".obj")
    assemble_args = ctx.actions.args()
    if ctx.attr.assembler == "armasm64":
        assemble_args.add("-nologo")
        assemble_args.add("-o", obj)
    else:
        assemble_args.add("/nologo")
        assemble_args.add("/c")
        assemble_args.add(obj, format = "/Fo%s")
    assemble_args.add(preprocessed)

    ctx.actions.run(
        outputs = [obj],
        inputs = depset(direct = [preprocessed], transitive = [cc_toolchain.all_files]),
        executable = _sibling(compiler, ctx.attr.assembler + ".exe"),
        arguments = [assemble_args],
        env = env,
        mnemonic = "MsvcAssemble",
        progress_message = "Assembling %s" % preprocessed.short_path,
    )

    return [DefaultInfo(files = depset([obj]))]

msvc_assemble = rule(
    implementation = _msvc_assemble_impl,
    doc = "Preprocess a .S with cl and assemble it, producing a single .obj.",
    attrs = {
        "src": attr.label(
            allow_single_file = [".S"],
            mandatory = True,
            doc = "The assembly source, in the assembler's own syntax.",
        ),
        "deps": attr.label_list(
            providers = [CcInfo],
            doc = "Targets whose headers and include paths the source needs.",
        ),
        "assembler": attr.string(
            values = ["ml64", "armasm64"],
            mandatory = True,
            doc = "Assembler basename, found next to cl.exe.",
        ),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(mandatory = True),
)
