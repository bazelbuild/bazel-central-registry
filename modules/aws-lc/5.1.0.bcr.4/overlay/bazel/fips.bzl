"""
Build the object file needed by AWS-LC's static FIPS library on Linux.

AWS-LC checks its cryptographic code at startup by calculating an HMAC-SHA256
checksum and comparing it with a checksum stored during the build. Ordinary
compilation is insufficient: the linker can change addresses in the compiled
code, which would make the startup checksum differ from the stored checksum.
AWS-LC provides two Go programs, `delocate` and `inject_hash`, to handle this.
This rule runs those programs as separate Bazel actions instead of invoking
AWS-LC's CMake build.

The build has five steps:
1. Compile bcm.c, which includes the FIPS cryptographic C sources, to assembly.
2. Preprocess the release's architecture-specific assembly sources.
3. Run delocate to combine the assembly and rewrite address references so that
   linking will not change the bytes covered by the startup checksum.
4. Assemble the result into a single object file.
5. Run inject_hash to calculate the checksum and store it in that object file.

The output is bcm.o. The aws-lc-fips module puts this file in its crypto
cc_library's srcs, together with AWS-LC sources outside the checksum region.
Applications then depend on that crypto library, or its SSL library, as usual.
This rule doesn't produce a complete library nor a shared library (.so).
Loading this file also does not change aws-lc's non-FIPS crypto target.

The caller supplies bcm.c, assembly, headers, and Bazel executable targets for
both Go programs from the same AWS-LC release. It should include the C files that
bcm.c includes in hdrs, and supply public and private headers through hdrs and deps.
asm_srcs ends up in the output bcm.o so the consuming cc_library doesn't need it.

Each action declares its source files and tools as inputs so Bazel can rerun it
when they change. Compiler tools come from the configured Bazel C/C++ toolchain;
to avoid host compiler dependencies, configure one that supplies its own tools.
The rule uses the release's generated assembly and needs no CMake, make, Perl,
or Go executable found through PATH. It supports Linux x86-64 and AArch64 static
builds; instrumentation/LTO compiler flags aren't supported.
"""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cpp_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _compile(ctx, toolchain, features, compilation, source, output, action, flags, mnemonic):
    variables = cc_common.create_compile_variables(
        cc_toolchain = toolchain,
        feature_configuration = features,
        source_file = source.path,
        output_file = output.path,
        user_compile_flags = flags,
        include_directories = compilation.includes,
        quote_include_directories = compilation.quote_includes,
        system_include_directories = depset(transitive = [compilation.system_includes, getattr(compilation, "external_includes", depset())]),
        preprocessor_defines = depset(ctx.attr.defines, transitive = [compilation.defines, compilation.local_defines]),
        use_pic = True,
    )
    command_line = cc_common.get_memory_inefficient_command_line(
        feature_configuration = features,
        action_name = action,
        variables = variables,
    )
    for flag in command_line:
        if any([flag.startswith(prefix) for prefix in ["-fsanitize", "-flto", "--coverage", "-fprofile"]]):
            fail("FIPS integrity construction does not support instrumentation or LTO: " + flag)
    arguments = ctx.actions.args()
    arguments.add_all(command_line)
    ctx.actions.run(
        executable = cc_common.get_tool_for_action(
            feature_configuration = features,
            action_name = action,
        ),
        arguments = [arguments],
        inputs = depset([source] + ctx.files.hdrs, transitive = [compilation.headers]),
        tools = toolchain.all_files,
        outputs = [output],
        env = cc_common.get_environment_variables(
            feature_configuration = features,
            action_name = action,
            variables = variables,
        ),
        mnemonic = mnemonic,
    )

def _fips_module_impl(ctx):
    if not ctx.target_platform_has_constraint(ctx.attr._linux[platform_common.ConstraintValueInfo]):
        fail("aws_lc_fips_module supports Linux static builds only")
    if not any([ctx.target_platform_has_constraint(c[platform_common.ConstraintValueInfo]) for c in [ctx.attr._x86_64, ctx.attr._aarch64]]):
        fail("aws_lc_fips_module supports x86_64 and aarch64 only")
    toolchain = find_cpp_toolchain(ctx)
    features = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    compilation = cc_common.merge_compilation_contexts(
        compilation_contexts = [dep[CcInfo].compilation_context for dep in ctx.attr.deps],
    )
    flags = ctx.fragments.cpp.copts + ctx.attr.copts
    bcm_asm = ctx.actions.declare_file(ctx.label.name + "/bcm.s")
    _compile(ctx, toolchain, features, compilation, ctx.file.src, bcm_asm, ACTION_NAMES.c_compile, flags + ctx.fragments.cpp.conlyopts + ["-S"], "AwsLcFipsCompile")

    # Preprocess each assembly input with the target toolchain before delocation.
    # This also lets delocate consume plain assembly without spawning a compiler.
    assembly = []
    for i, source in enumerate(ctx.files.asm_srcs):
        output = ctx.actions.declare_file(ctx.label.name + "/asm_{}.s".format(i))
        _compile(ctx, toolchain, features, compilation, source, output, ACTION_NAMES.preprocess_assemble, flags + ["-E", "-P"], "AwsLcFipsPreprocess")
        assembly.append(output)
    delocated = ctx.actions.declare_file(ctx.label.name + "/bcm-delocated.S")
    arguments = ctx.actions.args()
    arguments.add("-o", delocated)
    arguments.add_all(ctx.files.asm_headers)
    arguments.add(bcm_asm)
    arguments.add_all(assembly)
    ctx.actions.run(
        executable = ctx.executable.delocate,
        arguments = [arguments],
        inputs = [bcm_asm] + assembly + ctx.files.asm_headers,
        tools = [ctx.attr.delocate[DefaultInfo].files_to_run],
        outputs = [delocated],
        mnemonic = "AwsLcFipsDelocate",
    )
    unhashed = ctx.actions.declare_file(ctx.label.name + "/bcm-unhashed.o")

    # Prefix only after delocation, as in the upstream static FIPS build.
    prefixed_compilation = cc_common.merge_compilation_contexts(
        compilation_contexts = [dep[CcInfo].compilation_context for dep in ctx.attr.assembly_deps],
    ) if ctx.attr.assembly_deps else compilation
    _compile(ctx, toolchain, features, prefixed_compilation, delocated, unhashed, ACTION_NAMES.preprocess_assemble, flags, "AwsLcFipsAssemble")
    hashed = ctx.actions.declare_file(ctx.label.name + "/bcm.o")
    arguments = ctx.actions.args()
    arguments.add("-in-object", unhashed)
    arguments.add("-o", hashed)
    ctx.actions.run(
        executable = ctx.executable.inject_hash,
        arguments = [arguments],
        inputs = [unhashed],
        tools = [ctx.attr.inject_hash[DefaultInfo].files_to_run],
        outputs = [hashed],
        mnemonic = "AwsLcFipsInjectHash",
    )
    return [DefaultInfo(files = depset([hashed]))]

aws_lc_fips_module = rule(
    implementation = _fips_module_impl,
    attrs = {
        "src": attr.label(mandatory = True, allow_single_file = [".c"]),
        "hdrs": attr.label_list(allow_files = True),
        "asm_srcs": attr.label_list(mandatory = True, allow_files = [".S"]),
        "asm_headers": attr.label_list(allow_files = [".h"]),
        "deps": attr.label_list(providers = [CcInfo]),
        "assembly_deps": attr.label_list(providers = [CcInfo], doc = "Headers and prefix definitions applied after delocation."),
        "copts": attr.string_list(),
        "defines": attr.string_list(default = ["BORINGSSL_IMPLEMENTATION", "BORINGSSL_FIPS", "S2N_BN_HIDE_SYMBOLS"]),
        "delocate": attr.label(mandatory = True, executable = True, cfg = "exec"),
        "inject_hash": attr.label(mandatory = True, executable = True, cfg = "exec"),
        "_linux": attr.label(default = "@platforms//os:linux"),
        "_x86_64": attr.label(default = "@platforms//cpu:x86_64"),
        "_aarch64": attr.label(default = "@platforms//cpu:aarch64"),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
    provides = [DefaultInfo],
)
