"""Rules for accessing terminfo data"""

_DIR_TEMPLATE = """\
#!/usr/bin/env bash
set -euo pipefail
mkdir -p {output}
{cmds}
"""

def _terminfo_directory_impl(ctx):
    directory = ctx.actions.declare_directory(ctx.label.name)

    cmds = []
    if ctx.attr.fail_message:
        cmds.extend([
            ">&2 echo '{}'".format(ctx.attr.fail_message),
            "exit 1",
        ])

    for file in ctx.files.srcs:
        _, _, rel_dest = file.path.partition("/")
        dest = "{}/{}".format(directory.path, rel_dest)
        parent, _, _ = dest.rpartition("/")
        cmds.append("mkdir -p {} && cp {} {}".format(
            parent,
            file.path,
            dest,
        ))

    executable = ctx.actions.declare_file("{}.sh".format(ctx.label.name))
    ctx.actions.write(
        output = executable,
        content = _DIR_TEMPLATE.format(
            output = directory.path,
            cmds = "\n".join(cmds),
        ),
        is_executable = True,
    )

    ctx.actions.run(
        mnemonic = "NCursesTerminfo",
        executable = executable,
        outputs = [directory],
        inputs = ctx.files.srcs,
    )

    return [DefaultInfo(
        files = depset([directory]),
    )]

terminfo_directory = rule(
    doc = "A rule for bundling terminfo data.",
    implementation = _terminfo_directory_impl,
    attrs = {
        "fail_message": attr.string(
            doc = "An optional fail message for when `local_terminfo_repository` failed to find data.",
        ),
        "srcs": attr.label_list(
            doc = "Data to bundle.",
            allow_files = True,
            mandatory = True,
        ),
    },
)

_DEFAULT_TERMINFO_PATH = "/usr/share/terminfo"

_TEMPLATE = """\
load(":terminfo.bzl", "terminfo_directory")

terminfo_directory(
    name = "{name}",
    srcs = glob(["terminfo/**"], allow_empty = True),
    fail_message = {fail_message},
    visibility = ["//visibility:public"],
)
"""

def _local_terminfo_repository_impl(rctx):
    rctx.file("WORKSPACE.bazel", """workspace(name = "{}")""".format(
        rctx.name,
    ))

    fail_message = None
    terminfo_path = rctx.path(rctx.attr.path)
    if terminfo_path.exists:
        rctx.symlink(
            terminfo_path,
            rctx.path("terminfo"),
        )
    else:
        fail_message = "No host directory: {}".format(terminfo_path)

    terminfo_bzl = rctx.path(rctx.attr._terminfo_bzl)
    rctx.symlink(
        rctx.path(rctx.attr._terminfo_bzl),
        rctx.path(terminfo_bzl.basename),
    )

    rctx.file("BUILD.bazel", _TEMPLATE.format(
        name = rctx.attr.original_name,
        fail_message = repr(fail_message),
    ))

local_terminfo_repository = repository_rule(
    doc = "A repository for collecting local terminfo data.",
    implementation = _local_terminfo_repository_impl,
    attrs = {
        # TODO: This can be removed in Bazel 8 and it's use moved to `repository_ctx.original_name`.
        "original_name": attr.string(
            doc = "The original name of the repository.",
        ),
        "path": attr.string(
            doc = "The path to local terminfo data.",
            default = "/usr/share/terminfo",
        ),
        "_terminfo_bzl": attr.label(
            allow_files = True,
            default = Label("//bazel:terminfo.bzl"),
        ),
    },
    local = True,
)

_data_tag = tag_class(
    attrs = {
        "name": attr.string(
            doc = "The name of the module to create.",
            mandatory = True,
        ),
        "path": attr.string(
            doc = "The path to local terminfo data.",
            default = _DEFAULT_TERMINFO_PATH,
        ),
    },
)

def _local_terminfo_impl(module_ctx):
    root_module_direct_deps = []
    for mod in module_ctx.modules:
        for attrs in mod.tags.data:
            local_terminfo_repository(
                name = attrs.name,
                original_name = attrs.name,
                path = attrs.path,
            )
            if mod.is_root:
                root_module_direct_deps.append(attrs.name)

    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = root_module_direct_deps,
        root_module_direct_dev_deps = [],
    )

local_terminfo = module_extension(
    doc = "A module for locating terminfo data.",
    implementation = _local_terminfo_impl,
    tag_classes = {
        "data": _data_tag,
    },
)
