"""Rule to create a combined lz4 static archive for foreign_cc consumers."""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")

def _collect_objects_from_deps(deps):
    """Collect all object files from CcInfo providers in deps."""
    objects = []
    seen = {}
    for dep in deps:
        if CcInfo in dep:
            for linker_input in dep[CcInfo].linking_context.linker_inputs.to_list():
                for lib in linker_input.libraries:
                    objs = lib.pic_objects if lib.pic_objects else lib.objects
                    if objs:
                        for obj in objs:
                            if obj.path not in seen:
                                seen[obj.path] = True
                                objects.append(obj)
    return objects

def _collect_compilation_context(deps):
    """Merge compilation contexts from deps."""
    cc_infos = [dep[CcInfo] for dep in deps if CcInfo in dep]
    if not cc_infos:
        return None
    merged = cc_common.merge_cc_infos(cc_infos = cc_infos)
    return merged.compilation_context

def _lz4_combined_archive_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    objects = _collect_objects_from_deps(ctx.attr.deps)
    if not objects:
        fail("No objects found in deps")

    output_archive = ctx.actions.declare_file("lib" + ctx.attr.archive_name + ".a")

    archiver_path = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.cpp_link_static_library,
    )
    archiver_variables = cc_common.create_link_variables(
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        output_file = output_archive.path,
        is_using_linker = False,
    )
    command_line = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.cpp_link_static_library,
        variables = archiver_variables,
    )

    args = ctx.actions.args()
    args.add_all(command_line)
    args.add_all(objects)

    if cc_common.is_enabled(
        feature_configuration = feature_configuration,
        feature_name = "archive_param_file",
    ):
        args.use_param_file("@%s", use_always = True)

    env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.cpp_link_static_library,
        variables = archiver_variables,
    )

    ctx.actions.run(
        executable = archiver_path,
        arguments = [args],
        env = env,
        inputs = depset(
            direct = objects,
            transitive = [cc_toolchain.all_files],
        ),
        outputs = [output_archive],
        mnemonic = "Lz4CombinedArchive",
        progress_message = "Creating combined lz4 archive %{output}",
    )

    library_to_link = cc_common.create_library_to_link(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        static_library = output_archive,
        pic_static_library = output_archive,
    )

    linker_input = cc_common.create_linker_input(
        owner = ctx.label,
        libraries = depset([library_to_link]),
    )

    linking_context = cc_common.create_linking_context(
        linker_inputs = depset([linker_input]),
    )

    compilation_context = _collect_compilation_context(ctx.attr.deps)

    cc_info = CcInfo(
        compilation_context = compilation_context,
        linking_context = linking_context,
    )

    return [
        DefaultInfo(files = depset([output_archive])),
        cc_info,
    ]

lz4_combined_archive = rule(
    implementation = _lz4_combined_archive_impl,
    attrs = {
        "deps": attr.label_list(
            providers = [CcInfo],
            doc = "cc_library deps to combine into a single archive",
        ),
        "archive_name":  attr.string(
            default = "lz4",
            doc = "Name for the output archive (will produce lib<name>.a)",
        ),
        "_cc_toolchain": attr.label(
            default = "@bazel_tools//tools/cpp:current_cc_toolchain",
        ),
    },
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"],
)
