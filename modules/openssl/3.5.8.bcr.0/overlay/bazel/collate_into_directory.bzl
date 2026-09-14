"""Collate cc_library and cc_binary outputs into an install-style directory tree.

Extracts headers from CcInfo, library archives from DefaultInfo (libs),
and executables from DefaultInfo (bins), then copies everything into a
single output directory laid out as:

    include/   -- headers (preserving repo-relative paths)
    lib/       -- static/shared libraries
    bin/       -- executables
"""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _repo_prefix(ctx):
    """Return the execution-root prefix for source files in this repo."""
    ws = ctx.label.workspace_name
    if ws:
        return "external/" + ws
    return ""

def _strip_to_repo_relative(file, source_prefix, genfiles_path):
    """Compute the prefix to strip so the C++ tool sees the repo-relative remainder."""
    if file.path.startswith(genfiles_path + "/"):
        return genfiles_path + "/" + source_prefix if source_prefix else genfiles_path
    return source_prefix

def _build_manifest_content(ctx, outdir):
    """Build the TSV manifest consumed by the collate_into_directory binary.

    Returns:
        input_files: depset of all files that must be present for the action.
        manifest_content: newline-terminated TSV string.
    """
    source_prefix = _repo_prefix(ctx)
    genfiles_path = ctx.genfiles_dir.path
    manifest_lines = []
    input_depsets = []

    # --- Headers from CcInfo (libs only) ---
    all_headers = depset(transitive = [
        lib[CcInfo].compilation_context.headers
        for lib in ctx.attr.libs
    ])
    for hdr in all_headers.to_list():
        prefix = _strip_to_repo_relative(hdr, source_prefix, genfiles_path)
        manifest_lines.append("{}\t{}\t{}".format(outdir.path, hdr.path, prefix))
    input_depsets.append(all_headers)

    # --- Library archives from DefaultInfo (libs) ---
    for lib in ctx.attr.libs:
        for f in lib[DefaultInfo].files.to_list():
            manifest_lines.append("{}/lib\t{}\t{}".format(outdir.path, f.path, f.dirname))
        input_depsets.append(lib[DefaultInfo].files)

    # --- Executables from DefaultInfo (bins) ---
    for bin_target in ctx.attr.bins:
        for f in bin_target[DefaultInfo].files.to_list():
            manifest_lines.append("{}/bin\t{}\t{}".format(outdir.path, f.path, f.dirname))
        input_depsets.append(bin_target[DefaultInfo].files)

    input_files = depset(transitive = input_depsets)
    return input_files, "\n".join(manifest_lines) + "\n"

def _collate_into_directory_impl(ctx):
    outdir = ctx.actions.declare_directory(ctx.label.name)

    input_files, manifest_content = _build_manifest_content(ctx, outdir)

    manifest = ctx.actions.declare_file("{}.manifest".format(ctx.label.name))
    ctx.actions.write(
        output = manifest,
        content = manifest_content,
    )

    ctx.actions.run(
        inputs = depset([manifest], transitive = [input_files]),
        executable = ctx.executable._generator,
        arguments = [manifest.path],
        outputs = [outdir],
        mnemonic = "OpenSSLCollateIntoDir",
        progress_message = "Copying OpenSSL files to directory",
    )

    return [
        DefaultInfo(
            files = depset([outdir]),
            runfiles = ctx.runfiles(files = [outdir]),
        ),
    ]

collate_into_directory = rule(
    implementation = _collate_into_directory_impl,
    doc = "Collate cc_library headers and archives plus cc_binary executables into an install-style directory.",
    attrs = {
        "bins": attr.label_list(
            doc = "cc_binary targets whose executables are placed under bin/.",
        ),
        "libs": attr.label_list(
            providers = [CcInfo],
            doc = "cc_library targets. Headers from CcInfo go under include/; " +
                  "library archives from DefaultInfo go under lib/.",
        ),
        "_generator": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            default = Label("//bazel:collate_into_directory"),
        ),
    },
)
