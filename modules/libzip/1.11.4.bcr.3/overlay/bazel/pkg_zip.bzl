LibzipPkgZipInfo = provider(fields = ["zip"])

def _normalize_prefix(prefix):
    if prefix in ["", "."]:
        return ""
    return prefix.strip("/") + "/"

def _strip_prefix(path, prefix):
    normalized = _normalize_prefix(prefix)
    if normalized == "":
        return path
    if not path.startswith(normalized):
        fail("strip_prefix %r does not match input path %r" % (prefix, path))
    return path[len(normalized):]

def _repo_relative_path(src):
    path = src.short_path
    if path.startswith("../"):
        parts = path.split("/", 2)
        if len(parts) < 3:
            fail("invalid source path %r" % src.short_path)
        path = parts[2]
    return path

def _zip_path(src, strip_prefix, package_dir):
    path = _strip_prefix(_repo_relative_path(src), strip_prefix)
    package_dir = package_dir.strip("/")
    if package_dir:
        path = package_dir + "/" + path
    if path == "" or path.startswith("/") or "/../" in path or path.startswith("../") or path.endswith("/.."):
        fail("invalid zip entry path %r for source %s" % (path, src.short_path))
    return path

def _file_manifest_line(src, path, mode):
    return "F\t%s\t%s\t%s\n" % (src.path, path, mode)

def _zip_manifest_line(zip_file):
    return "Z\t%s\n" % zip_file.path

def _libzip_pkg_zip_impl(ctx):
    output = ctx.outputs.out
    manifest = ctx.actions.declare_file(ctx.label.name + ".manifest")
    entries = []
    dep_zips = []
    seen = {}

    for src in ctx.files.srcs:
        path = _zip_path(src, ctx.attr.strip_prefix, ctx.attr.package_dir)
        if path in seen:
            fail("duplicate zip entry path %r from %s and %s" % (path, seen[path], src.short_path))
        seen[path] = src.short_path
        mode = ctx.attr.modes.get(path, ctx.attr.mode)
        entries.append((path, _file_manifest_line(src, path, mode)))

    for dep in ctx.attr.deps:
        dep_zips.append(dep[LibzipPkgZipInfo].zip)

    entries = sorted(entries)
    ctx.actions.write(
        output = manifest,
        content = "".join([entry[1] for entry in entries] + [_zip_manifest_line(zip_file) for zip_file in dep_zips]),
    )

    args = ctx.actions.args()
    args.add(output)
    args.add(manifest)

    ctx.actions.run(
        inputs = ctx.files.srcs + dep_zips + [manifest],
        outputs = [output],
        executable = ctx.executable._zip_tool,
        arguments = [args],
        mnemonic = "LibzipPkgZip",
        progress_message = "Creating zip %{output}",
    )

    return [
        DefaultInfo(files = depset([output])),
        LibzipPkgZipInfo(zip = output),
    ]

libzip_pkg_zip = rule(
    implementation = _libzip_pkg_zip_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [LibzipPkgZipInfo]),
        "out": attr.output(mandatory = True),
        "package_dir": attr.string(default = ""),
        "strip_prefix": attr.string(default = "."),
        "mode": attr.string(default = "0644"),
        "modes": attr.string_dict(),
        "_zip_tool": attr.label(
            default = Label("//:libzip_pkg_zip_tool"),
            executable = True,
            cfg = "exec",
        ),
    },
)
