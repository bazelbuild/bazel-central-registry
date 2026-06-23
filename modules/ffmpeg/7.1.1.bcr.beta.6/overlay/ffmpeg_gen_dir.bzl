load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

_HEADER_SUFFIXES = (
    ".h",
    ".hh",
    ".hpp",
    ".hxx",
)

_LIBRARY_SUFFIXES = (
    ".a",
    ".so",
    ".dylib",
    ".dll",
    ".lib",
)

def _first_nonempty(*values):
    for value in values:
        if value:
            return value
    return None

def _is_safe_relpath(path):
    return not (
        path.startswith("/") or
        path == ".." or
        path.startswith("../") or
        path.endswith("/..") or
        "/../" in path
    )

def _workspace_relpath(file, workspace_name):
    short_path = file.short_path
    external_prefix = "external/{}/".format(workspace_name)
    if short_path.startswith(external_prefix):
        return short_path[len(external_prefix):]
    parent_workspace_prefix = "../{}/".format(workspace_name)
    if short_path.startswith(parent_workspace_prefix):
        return short_path[len(parent_workspace_prefix):]
    workspace_prefix = workspace_name + "/"
    if short_path.startswith(workspace_prefix):
        return short_path[len(workspace_prefix):]
    if short_path.startswith("../"):
        return None
    if not short_path.startswith("external/"):
        return short_path
    return None

def _header_relpath(file, workspace_name):
    relpath = _workspace_relpath(file, workspace_name)
    if not relpath or not _is_safe_relpath(relpath) or not relpath.endswith(_HEADER_SUFFIXES):
        return None
    return relpath

def _strip_prefix_for_relpath(file, relpath):
    suffix = "/" + relpath
    if file.path == relpath:
        return ""
    if file.path.endswith(suffix):
        return file.path[:-len(suffix)]
    fail("could not compute strip prefix for {} from relative path {}".format(file.path, relpath))

def _is_library_file(basename):
    return basename.endswith(_LIBRARY_SUFFIXES)

def _library_name(basename):
    name = basename
    for suffix in _LIBRARY_SUFFIXES:
        if name.endswith(suffix):
            name = name[:-len(suffix)]
            break
    if name.startswith("lib"):
        name = name[3:]
    return name

def _library_descriptor(library):
    file = _first_nonempty(
        library.pic_static_library,
        library.static_library,
        library.dynamic_library,
        library.interface_library,
    )
    if not file:
        return None

    basename = file.basename
    if basename.endswith(".a"):
        kind = "static"
    elif basename.endswith(".so") or basename.endswith(".dylib") or basename.endswith(".dll"):
        kind = "dylib"
    else:
        kind = "dylib"

    return struct(
        file = file,
        basename = basename,
        kind = kind,
        name = _library_name(basename),
    )

def _link_flag(flag):
    if flag:
        return flag
    return None

def _ffmpeg_install_tree_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name)

    install_manifest_lines = []
    header_inputs = []
    seen_headers = {}

    library_inputs = []
    seen_libraries = {}
    primary_libraries = {}

    link_flags = []
    seen_link_flags = {}

    for dep in ctx.attr.deps:
        cc_info = dep[CcInfo]
        workspace_name = dep.label.workspace_name or ctx.workspace_name

        for header in cc_info.compilation_context.headers.to_list():
            relpath = _header_relpath(header, workspace_name)
            if not relpath or relpath in seen_headers:
                continue
            seen_headers[relpath] = True
            header_inputs.append(header)
            install_manifest_lines.append("{}\t{}\t{}".format(
                out.path + "/include",
                header.path,
                _strip_prefix_for_relpath(header, relpath),
            ))

        for file in dep[DefaultInfo].files.to_list():
            if not _is_library_file(file.basename):
                continue
            descriptor = _library_descriptor(struct(
                pic_static_library = None,
                static_library = file,
                dynamic_library = None,
                interface_library = None,
            ))
            if not descriptor:
                continue
            primary_libraries[descriptor.basename] = True
            if descriptor.basename in seen_libraries:
                continue
            seen_libraries[descriptor.basename] = True
            library_inputs.append(descriptor.file)
            install_manifest_lines.append("{}\t{}\t{}".format(
                out.path + "/lib",
                descriptor.file.path,
                descriptor.file.dirname,
            ))

        for linker_input in cc_info.linking_context.linker_inputs.to_list():
            for flag in linker_input.user_link_flags:
                link_flag = _link_flag(flag)
                if link_flag and link_flag not in seen_link_flags:
                    seen_link_flags[link_flag] = True
                    link_flags.append(link_flag)

            for library in linker_input.libraries:
                descriptor = _library_descriptor(library)
                if not descriptor:
                    continue

                if descriptor.basename not in seen_libraries:
                    seen_libraries[descriptor.basename] = True
                    library_inputs.append(descriptor.file)
                    install_manifest_lines.append("{}\t{}\t{}".format(
                        out.path + "/lib",
                        descriptor.file.path,
                        descriptor.file.dirname,
                    ))

                if descriptor.basename in primary_libraries:
                    continue

                link_flag = "-l{}".format(descriptor.name)
                if link_flag in seen_link_flags:
                    continue
                seen_link_flags[link_flag] = True
                link_flags.append(link_flag)

    install_manifest = ctx.actions.declare_file(ctx.label.name + "_install_tree.tsv")
    link_flags_manifest = ctx.actions.declare_file(ctx.label.name + "_install_tree/link-flags.txt")

    ctx.actions.write(link_flags_manifest, "\n".join(link_flags) + ("\n" if link_flags else ""))
    install_manifest_lines.append("{}\t{}\t{}".format(
        out.path,
        link_flags_manifest.path,
        link_flags_manifest.dirname,
    ))
    ctx.actions.write(install_manifest, "\n".join(install_manifest_lines) + "\n")

    inputs = depset(
        direct = header_inputs + library_inputs + [
            install_manifest,
            link_flags_manifest,
        ],
    )

    ctx.actions.run(
        inputs = inputs,
        outputs = [out],
        executable = ctx.executable._install_tree_tool,
        arguments = [install_manifest.path],
        mnemonic = "FfmpegInstallTree",
        progress_message = "Materializing FFmpeg install tree {}".format(ctx.label),
    )

    return [DefaultInfo(files = depset([out]))]

ffmpeg_install_tree = rule(
    implementation = _ffmpeg_install_tree_impl,
    attrs = {
        "deps": attr.label_list(
            mandatory = True,
            providers = [CcInfo],
        ),
        "_install_tree_tool": attr.label(
            allow_single_file = True,
            default = Label("//:_ffmpeg_install_tree_tool"),
            executable = True,
            cfg = "exec",
        ),
    },
)
