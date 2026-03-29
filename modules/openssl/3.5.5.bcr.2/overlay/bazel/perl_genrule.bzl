"""Generate assembly files from OpenSSL's perlasm scripts.

Each perlasm script is run as an individual action for per-file caching
and full parallelism. No shell scripts are generated.
"""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:defs.bzl", "CcInfo", "cc_common")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")

def _perl_genrule_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    env = {
        "CC": cc_common.get_tool_for_action(
            feature_configuration = feature_configuration,
            action_name = ACTION_NAMES.c_compile,
        ),
    }

    perl_runtime = ctx.attr._perl_toolchain[platform_common.ToolchainInfo].perl_runtime
    perl_interpreter = perl_runtime.interpreter
    additional_srcs = []
    for src in ctx.attr.additional_srcs:
        additional_srcs.extend(src.files.to_list())

    tools = depset(
        direct = [perl_interpreter],
        transitive = [cc_toolchain.all_files, perl_runtime.runtime],
    )

    outs_as_files = []
    all_dicts = [ctx.attr.srcs_to_outs, ctx.attr.srcs_to_outs_dupes]
    for src_to_out_dict in all_dicts:
        for src, out in src_to_out_dict.items():
            src_file = src.files.to_list()[0]
            out_file = ctx.actions.declare_file(out)
            outs_as_files.append(out_file)

            ctx.actions.run(
                executable = perl_interpreter,
                arguments = [src_file.path, ctx.attr.assembly_flavor, out_file.path],
                inputs = depset(direct = [src_file] + additional_srcs),
                outputs = [out_file],
                env = env,
                tools = tools,
                mnemonic = "OpenSSLPerlasm",
            )

    if not outs_as_files:
        return [
            DefaultInfo(files = depset()),
            CcInfo(compilation_context = cc_common.create_compilation_context()),
        ]

    return [
        DefaultInfo(files = depset(outs_as_files)),
        CcInfo(
            compilation_context = cc_common.create_compilation_context(
                direct_private_headers = outs_as_files,
            ),
        ),
    ]

perl_genrule = rule(
    implementation = _perl_genrule_impl,
    doc = "Generate assembly files from OpenSSL perlasm scripts.",
    attrs = {
        "additional_srcs": attr.label_list(
            doc = "Additional input files used by the perlasm scripts.",
            allow_files = True,
        ),
        "assembly_flavor": attr.string(
            doc = "Assembly output format (e.g. elf, ios64, masm).",
        ),
        "srcs_to_outs": attr.label_keyed_string_dict(
            doc = "Dict of perlasm script to output file path.",
            allow_files = True,
        ),
        "srcs_to_outs_dupes": attr.label_keyed_string_dict(
            doc = "Dict of perlasm script to output file path for scripts that appear in srcs_to_outs with a different output.",
            allow_files = True,
        ),
        "_perl_toolchain": attr.label(
            cfg = "exec",
            default = Label("@rules_perl//perl:current_toolchain"),
        ),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)
