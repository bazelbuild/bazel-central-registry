"""Rules that generate private_namespace.h from the library's symbols, check the library against it, and resolve
JEMALLOC_PRIVATE_NAMESPACE."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

# The private namespace of private_namespace_jet.h, under JEMALLOC_JET
JET_PREFIX = "jet_"

def _static_archives(target):
    """The static archives of this repository's linker inputs in target's CcInfo."""
    archives = []
    for linker_input in target[CcInfo].linking_context.linker_inputs.to_list():
        # This repository owns the library's own linker inputs, so a dependency's archive (libunwind) is not read as
        # jemalloc's.
        if linker_input.owner.repo_name != Label("//:BUILD.bazel").repo_name:
            continue
        for library in linker_input.libraries:
            for archive in [library.static_library, library.pic_static_library]:
                if archive != None and archive not in archives:
                    archives.append(archive)
    return archives

def _sibling(path, name):
    """The file `name` in the directory of `path`, a path written with slashes or with backslashes. That is `name`
    alone for a path with no directory, which a program search finds as it finds `path`."""
    return path[:max(path.rfind("/"), path.rfind("\\")) + 1] + name

def _symbol_lister(ctx, cc_toolchain):
    """The program that lists the archives' symbols, and the options it takes before them.

    That is the //settings/flags:nm target if set, otherwise the C++ toolchain's own lister: its nm_executable, as
    configure's NM, run as `nm -a`. An MSVC-compatible toolchain declares no nm (rules_cc's are a no-op placeholder),
    so for msvc-cl it is the toolchain's linker as `link /DUMP /SYMBOLS`, which is dumpbin, whose listing
    private_symbols.awk also reads, and for clang-cl the llvm-nm.exe of the LLVM installation its clang-cl.exe is in.
    Those run with the toolchain's environment for the action whose tool they are.

    Returns a struct of the lister's path, its options, the tools and inputs its action needs and its environment.
    """

    # toolchain_nm is the flag's unset value.
    if ctx.attr._nm.label != Label("//settings/flags:toolchain_nm"):
        flag = ctx.attr._nm[DefaultInfo]
        executable = flag.files_to_run.executable
        if executable != None:
            tool = flag.files_to_run
        else:
            files = flag.files.to_list()
            if len(files) != 1:
                fail("//settings/flags:nm must name one executable, but {} provides {}".format(ctx.attr._nm.label, files))
            executable = files[0]
            tool = executable

        # On POSIX hosts private_namespace_gen runs nm with posix_spawnp, which searches PATH for a name without a
        # slash, as the path of a file in the main repository's root package is.
        path = executable.path if "/" in executable.path else "./" + executable.path
        return struct(path = path, arguments = ["-a"], tools = [tool], inputs = [], env = {})
    if cc_toolchain.compiler not in ["clang-cl", "msvc-cl"]:
        return struct(path = cc_toolchain.nm_executable, arguments = ["-a"], tools = [], inputs = [cc_toolchain.all_files], env = {})
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    if cc_toolchain.compiler == "msvc-cl":
        action_name = ACTION_NAMES.cpp_link_executable
        path = cc_common.get_tool_for_action(feature_configuration = feature_configuration, action_name = action_name)
        arguments = ["/DUMP", "/SYMBOLS"]
    else:
        action_name = ACTION_NAMES.c_compile
        compiler = cc_common.get_tool_for_action(feature_configuration = feature_configuration, action_name = action_name)
        path = _sibling(compiler, "llvm-nm.exe")
        arguments = ["-a"]
    env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = action_name,
        variables = cc_common.empty_variables(),
    )
    return struct(path = path, arguments = arguments, tools = [], inputs = [cc_toolchain.all_files], env = env)

def _linker_input_owners(target):
    return [str(linker_input.owner) for linker_input in target[CcInfo].linking_context.linker_inputs.to_list()]

def _jemalloc_private_namespace_impl(ctx):
    # Equivalent of JEMALLOC_PRIVATE_NAMESPACE="${with_private_namespace}je_"
    value = ctx.attr._private_namespace[BuildSettingInfo].value + "je_"

    # The prefix jemalloc's internal symbols carry: private_namespace_jet.h's under JEMALLOC_JET, and none without a
    # private namespace
    if ctx.attr._no_private_namespace[BuildSettingInfo].value:
        internal_prefix = ""
    elif ctx.attr._jet[BuildSettingInfo].value:
        internal_prefix = JET_PREFIX
    else:
        internal_prefix = value
    return [
        BuildSettingInfo(value = value),
        platform_common.TemplateVariableInfo({
            "JEMALLOC_INTERNAL_PREFIX": internal_prefix,
            "JEMALLOC_PRIVATE_NAMESPACE": value,
        }),
    ]

jemalloc_private_namespace = rule(
    doc = "JEMALLOC_PRIVATE_NAMESPACE, the private_namespace flag followed by \"je_\", as a BuildSettingInfo for " +
          "rules_cc_autoconf's AC_BUILD_SETTING and as the $(JEMALLOC_PRIVATE_NAMESPACE) make variable, and the prefix " +
          "of jemalloc's internal symbols in this configuration as $(JEMALLOC_INTERNAL_PREFIX).",
    implementation = _jemalloc_private_namespace_impl,
    attrs = {
        "_jet": attr.label(default = "//settings:enable_jet"),
        "_no_private_namespace": attr.label(default = "//settings:enable_no_private_namespace"),
        "_private_namespace": attr.label(default = "//settings/flags:private_namespace"),
    },
)

def _private_namespace_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    prefix = ctx.attr.prefix if ctx.attr.prefix else ctx.attr._prefix[BuildSettingInfo].value

    output = ctx.actions.declare_file(ctx.attr.out)
    if bool(ctx.attr.input) == bool(ctx.file.listing):
        fail("set exactly one of input and listing")
    lister_stderr = ctx.actions.declare_file(ctx.label.name + ".listing.stderr")
    sym_prefix = ctx.attr.sym_prefix
    listing = ctx.actions.declare_file(ctx.label.name + ".listing")
    if ctx.file.listing:
        # A checked-in listing is named for the tool that wrote it (.nm, .dumpbin). Linking it to <name>.listing gives
        # the upstream_inputs output group the same path whether the listing is checked in or generated.
        ctx.actions.symlink(output = listing, target_file = ctx.file.listing)
        ctx.actions.write(output = lister_stderr, content = "")
        listing_source = ctx.file.listing.short_path
        unfound_reason = "public_symbols, prefix or sym_prefix does not match it"
    else:
        lister = _symbol_lister(ctx, cc_toolchain)
        listing_source = "`{}`".format(" ".join([lister.path] + lister.arguments))
        unfound_reason = "it read no symbol table (for example from LTO bitcode it cannot parse)"
        archives = _static_archives(ctx.attr.input[0])
        if not archives:
            fail("{} provides no static archive to list; its linker inputs are owned by {}".format(ctx.attr.input[0].label, _linker_input_owners(ctx.attr.input[0])))
        ctx.actions.run(
            executable = ctx.executable._generator,
            arguments = ["list", lister.path, listing.path, lister_stderr.path] + lister.arguments + [archive.path for archive in archives],
            env = lister.env,
            inputs = depset(archives, transitive = lister.inputs),
            outputs = [listing, lister_stderr],
            tools = lister.tools,
            mnemonic = "PrivateNamespaceList",
        )

    export_syms = ctx.actions.declare_file(ctx.label.name + ".export_syms")
    args = ctx.actions.args()
    args.add_all(["header", output.path, listing, lister_stderr, sym_prefix, listing_source, unfound_reason])
    args.add(prefix, format = "--prefix=%s")
    args.add(ctx.file.public_symbols, format = "--public-file=%s")
    args.add(ctx.file.wrap_symbols, format = "--wrap-file=%s")
    args.add(export_syms, format = "--export-syms=%s")
    ctx.actions.run(
        executable = ctx.executable._generator,
        arguments = [args],
        inputs = [listing, lister_stderr, ctx.file.public_symbols, ctx.file.wrap_symbols],
        outputs = [output, export_syms],
        mnemonic = "PrivateNamespace",
    )

    return [
        DefaultInfo(files = depset([output])),
        OutputGroupInfo(
            export_syms = depset([export_syms]),
            upstream_inputs = depset([listing, export_syms]),
        ),
    ]

def _transition_impl(_settings, attr):
    return {
        # Only C sources are used for symbol extraction
        "//settings/flags:enable_cxx": "False",
        "//settings:enable_no_private_namespace": True,
        "//settings:enable_jet": attr.enable_jet,
    }

transition_config_settings = transition(
    implementation = _transition_impl,
    inputs = [],
    outputs = ["//settings/flags:enable_cxx", "//settings:enable_no_private_namespace", "//settings:enable_jet"],
)

private_namespace = rule(
    doc = "Generate the private namespace header from the symbol listing of `input`, `nm -a` or dumpbin's, as upstream's private_symbols.awk " +
          "and private_namespace.sh do. Output group `export_syms` holds configure's export_syms, and " +
          "`upstream_inputs` holds that and the listing.",
    implementation = _private_namespace_impl,
    attrs = {
        "prefix": attr.string(doc = "Explicit prefix for public symbols, overrides value selected by build setting."),
        "public_symbols": attr.label(
            doc = "configure.ac's public_syms, one symbol per line, as a symbol_list writes it.",
            allow_single_file = True,
            mandatory = True,
        ),
        "input": attr.label(
            doc = "Compiled object achive from which to extract the symbols. A transition is forced to compile with JEMALLOC_NO_PRIVATE_NAMESPACE",
            cfg = transition_config_settings,
            providers = [CcInfo],
        ),
        "enable_jet": attr.bool(default = False),
        "listing": attr.label(
            doc = "An `nm -a` or `dumpbin /SYMBOLS` listing to use in place of listing `input`.",
            allow_single_file = True,
        ),
        "out": attr.string(
            doc = "Name of the generated file",
            mandatory = True,
        ),
        "sym_prefix": attr.string(
            doc = "configure's SYM_PREFIX: \"_\" for Mach-O targets, or whatever a `listing`'s format fixes.",
            mandatory = True,
            values = ["", "_"],
        ),
        "wrap_symbols": attr.label(
            doc = "configure.ac's wrap_syms, exported without prefix, one symbol per line, as a symbol_list writes it.",
            allow_single_file = True,
            mandatory = True,
        ),
        "_prefix": attr.label(default = "//settings/flags:jemalloc_prefix_resolved"),
        "_cc_toolchain": attr.label(default = Label("@rules_cc//cc:current_cc_toolchain")),
        "_nm": attr.label(
            doc = "//settings/flags:nm, an nm to run in place of the toolchain's.",
            default = "//settings/flags:nm",
            cfg = "exec",
            allow_files = True,
        ),
        "_generator": attr.label(
            default = Label("//tools/generators:private_namespace_gen"),
            cfg = "exec",
            executable = True,
        ),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(True),
)

def _rlocationpath(ctx, file):
    return file.short_path[3:] if file.short_path.startswith("../") else ctx.workspace_name + "/" + file.short_path

def _private_namespace_leak_test_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    archives = _static_archives(ctx.attr.library)
    if not archives:
        fail("expected a static archive from {}; its linker inputs are owned by {}".format(ctx.attr.library.label, _linker_input_owners(ctx.attr.library)))
    namespace = ctx.attr.namespace
    export_syms = namespace[OutputGroupInfo].export_syms.to_list()[0]
    header = namespace[DefaultInfo].files.to_list()[0]

    lister = _symbol_lister(ctx, cc_toolchain)
    listing = ctx.actions.declare_file(ctx.label.name + ".listing")
    lister_stderr = ctx.actions.declare_file(ctx.label.name + ".listing.stderr")
    ctx.actions.run(
        executable = ctx.executable._generator,
        arguments = ["list", lister.path, listing.path, lister_stderr.path] + lister.arguments + [archive.path for archive in archives],
        env = lister.env,
        inputs = depset(archives, transitive = lister.inputs),
        outputs = [listing, lister_stderr],
        tools = lister.tools,
        mnemonic = "PrivateNamespaceLeakList",
    )

    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(output = executable, target_file = ctx.executable._checker, is_executable = True)

    return [
        DefaultInfo(
            executable = executable,
            runfiles = ctx.runfiles(files = [listing, lister_stderr, export_syms, header]).merge(ctx.attr._checker[DefaultInfo].default_runfiles),
        ),
        RunEnvironmentInfo(environment = {
            "PRIVATE_NAMESPACE_LEAK_STDERR": _rlocationpath(ctx, lister_stderr),
            "PRIVATE_NAMESPACE_LEAK_EXPORTS": _rlocationpath(ctx, export_syms),
            "PRIVATE_NAMESPACE_LEAK_HEADER": _rlocationpath(ctx, header),
            "PRIVATE_NAMESPACE_LEAK_LISTING": _rlocationpath(ctx, listing),
            "PRIVATE_NAMESPACE_LEAK_PREFIX": ctx.attr._private_namespace[BuildSettingInfo].value + "je_",
            "PRIVATE_NAMESPACE_LEAK_SYM_PREFIX": ctx.attr.sym_prefix,
        }),
    ]

private_namespace_leak_test = rule(
    doc = "Checks that `library` defines no symbol outside the public API, the wrapped symbols and the private namespace.",
    implementation = _private_namespace_leak_test_impl,
    test = True,
    attrs = {
        "library": attr.label(doc = "The library consumers link.", mandatory = True, providers = [CcInfo]),
        "namespace": attr.label(
            doc = "The private_namespace target that names the exported and private symbols.",
            mandatory = True,
        ),
        "sym_prefix": attr.string(doc = "configure's SYM_PREFIX for the target platform.", mandatory = True, values = ["", "_"]),
        "_cc_toolchain": attr.label(default = Label("@rules_cc//cc:current_cc_toolchain")),
        "_nm": attr.label(
            doc = "//settings/flags:nm, an nm to run in place of the toolchain's.",
            default = "//settings/flags:nm",
            cfg = "exec",
            allow_files = True,
        ),
        "_private_namespace": attr.label(default = "//settings/flags:private_namespace"),
        "_checker": attr.label(
            default = Label("//tools/generators:private_namespace_leak_check"),
            cfg = "target",
            executable = True,
        ),
        "_generator": attr.label(
            default = Label("//tools/generators:private_namespace_gen"),
            cfg = "exec",
            executable = True,
        ),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(True),
)
