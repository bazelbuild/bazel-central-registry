"""Rules that generate private_namespace.h from the library's symbols, check the library against it, and resolve
JEMALLOC_PRIVATE_NAMESPACE."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

# This repository, as the owner of the library's own linker inputs, so that a dependency's archive (libunwind) is not
# read as jemalloc's.
_REPO = Label("//:BUILD.bazel").repo_name

# The unset value of //settings/flags:nm.
_TOOLCHAIN_NM = Label("//settings/flags:toolchain_nm")

# The private namespace of private_namespace_jet.h, under JEMALLOC_JET
JET_PREFIX = "jet_"

def _static_archives(target):
    """The static archives of this repository's linker inputs in target's CcInfo."""
    archives = []
    for linker_input in target[CcInfo].linking_context.linker_inputs.to_list():
        if linker_input.owner.repo_name != _REPO:
            continue
        for library in linker_input.libraries:
            for archive in [library.static_library, library.pic_static_library]:
                if archive != None and archive not in archives:
                    archives.append(archive)
    return archives

def _nm(ctx, cc_toolchain):
    """The nm to run: the //settings/flags:nm target if set, otherwise the toolchain's nm_executable.

    Returns a struct of the nm's path, the tools its action needs and the inputs (the toolchain's files, for its nm).
    """
    if ctx.attr._nm.label == _TOOLCHAIN_NM:
        return struct(path = cc_toolchain.nm_executable, tools = [], inputs = [cc_toolchain.all_files])
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

    # private_namespace_gen runs nm with posix_spawnp, which searches PATH for a name without a slash, as the path of a
    # file in the main repository's root package is.
    path = executable.path if "/" in executable.path else "./" + executable.path
    return struct(path = path, tools = [tool], inputs = [])

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
    nm_stderr = ctx.actions.declare_file(ctx.label.name + ".nm.stderr")
    sym_prefix = ctx.attr.sym_prefix
    if ctx.file.listing:
        listing = ctx.file.listing
        ctx.actions.write(output = nm_stderr, content = "")
        listing_source = listing.short_path
        unfound_reason = "public_symbols, prefix or sym_prefix does not match it"
    else:
        nm = _nm(ctx, cc_toolchain)
        listing_source = "`{}`".format(nm.path)
        unfound_reason = "it read no symbol table (for example from LTO bitcode it cannot parse)"
        archives = _static_archives(ctx.attr.input[0])
        if not archives:
            fail("{} provides no static archive to list; its linker inputs are owned by {}".format(ctx.attr.input[0].label, _linker_input_owners(ctx.attr.input[0])))
        listing = ctx.actions.declare_file(ctx.label.name + ".nm")
        ctx.actions.run(
            executable = ctx.executable._generator,
            arguments = ["nm", nm.path, listing.path, nm_stderr.path] + [archive.path for archive in archives],
            inputs = depset(archives, transitive = nm.inputs),
            outputs = [listing, nm_stderr],
            tools = nm.tools,
            mnemonic = "PrivateNamespaceNM",
        )

    export_syms = ctx.actions.declare_file(ctx.label.name + ".export_syms")
    args = ctx.actions.args()
    args.add_all(["header", output.path, listing, nm_stderr, sym_prefix, listing_source, unfound_reason])
    args.add(prefix, format = "--prefix=%s")
    args.add(ctx.file.public_symbols, format = "--public-file=%s")
    args.add(ctx.file.wrap_symbols, format = "--wrap-file=%s")
    args.add(export_syms, format = "--export-syms=%s")
    ctx.actions.run(
        executable = ctx.executable._generator,
        arguments = [args],
        inputs = [listing, nm_stderr, ctx.file.public_symbols, ctx.file.wrap_symbols],
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
        "//settings/flags:enable_cxx": False,
        "//settings:enable_no_private_namespace": True,
        "//settings:enable_jet": attr.enable_jet,
    }

transition_config_settings = transition(
    implementation = _transition_impl,
    inputs = [],
    outputs = ["//settings/flags:enable_cxx", "//settings:enable_no_private_namespace", "//settings:enable_jet"],
)

private_namespace = rule(
    doc = "Generate the private namespace header from the `nm -a` listing of `input`, as upstream's private_symbols.awk " +
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

    nm = _nm(ctx, cc_toolchain)
    listing = ctx.actions.declare_file(ctx.label.name + ".nm")
    nm_stderr = ctx.actions.declare_file(ctx.label.name + ".nm.stderr")
    ctx.actions.run(
        executable = ctx.executable._generator,
        arguments = ["nm", nm.path, listing.path, nm_stderr.path] + [archive.path for archive in archives],
        inputs = depset(archives, transitive = nm.inputs),
        outputs = [listing, nm_stderr],
        tools = nm.tools,
        mnemonic = "PrivateNamespaceLeakNM",
    )

    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(output = executable, target_file = ctx.executable._checker, is_executable = True)

    return [
        DefaultInfo(
            executable = executable,
            runfiles = ctx.runfiles(files = [listing, nm_stderr, export_syms, header]).merge(ctx.attr._checker[DefaultInfo].default_runfiles),
        ),
        RunEnvironmentInfo(environment = {
            "PRIVATE_NAMESPACE_LEAK_STDERR": _rlocationpath(ctx, nm_stderr),
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
    toolchains = use_cc_toolchain(True),
)
