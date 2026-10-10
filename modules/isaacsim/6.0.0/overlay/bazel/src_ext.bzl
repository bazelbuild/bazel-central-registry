"""Builds a Kit extension out of the Isaac Sim source tree.

This is the Bazel equivalent of what Isaac Sim's premake5.lua does for a
pure-Python extension: assemble a directory that Kit accepts as an extension.

The layout is not guessed: each extension's premake5.lua declares where its files
go, and the rules differ per extension. `isaacsim.core.experimental.utils`, for
example, copies `python/mock/*.py` *flat* into the package root -- that is where
`isaacsim.core.experimental.utils.ops` comes from -- while relocating
`python/impl` into a subpackage. Assuming a uniform layout builds an extension
that Kit loads but whose submodules cannot be imported, which then cascades into
"No module named ..." across everything that depends on it.

//bazel:gen_source_exts.py extracts those rules into //bazel:source_exts.bzl and
they arrive here as the `mapping` attribute. Paths not covered by any rule are
dropped, except config/, which Kit requires.

Extensions with `.ogn` node definitions also need their databases generated
first; //bazel:ogn.bzl does that and hands the result over as `ogn_generated`.
"""

# Every packman package that publishes a payload of this kind roots it here,
# and premake's copy rules name that directory explicitly too.
_PAYLOAD_ROOT = "omni/sensors"

IsaacSimExtensionInfo = provider(
    doc = "A Kit extension built from the Isaac Sim source tree.",
    fields = {
        "extension_name": "Extension id, e.g. \"isaacsim.core.experimental.utils\".",
        "manifest": "Its config/extension.toml source file.",
        "root": "Directory artifact holding <extension_name>/..., i.e. an --ext-folder.",
    },
)

def _rel_within_ext(path, ext_name):
    """Path relative to the extension root, or None if outside it."""

    # Extensions live under source/extensions/ or source/deprecated/; the latter
    # are still shipped and still referenced by the stock app configs. The
    # prefix in front of source/ varies (main repo vs. external repo vs.
    # generated-file roots), so match the marker anywhere on a path boundary.
    for subdir in ("extensions", "deprecated"):
        marker = "source/{subdir}/{ext}/".format(subdir = subdir, ext = ext_name)
        if path.startswith(marker):
            return path[len(marker):]
        idx = path.find("/" + marker)
        if idx != -1:
            return path[idx + 1 + len(marker):]
    return None

def _basename(path):
    parts = path.rsplit("/", 1)
    return parts[1] if len(parts) == 2 else path

def _dirname(path):
    parts = path.rsplit("/", 1)
    return parts[0] if len(parts) == 2 else ""

def _dest_within_ext(rel, mapping):
    """Where premake would place a source-relative path, or None to drop it."""

    # Kit needs the manifest regardless; premake handles config/ outside the
    # prebuild blocks, so it is rarely listed there.
    if rel.startswith("config/"):
        return rel

    best = None
    best_score = -1
    for src, dest in mapping.items():
        score = -1
        out = None
        if src.find("*") != -1:
            # A glob such as "python/*.py" copies matching files in that one
            # directory, flattened into dest.
            src_dir = _dirname(src)
            pattern = _basename(src)
            if _dirname(rel) == src_dir and pattern.startswith("*") and \
               rel.endswith(pattern[1:]):
                out = dest + "/" + _basename(rel) if dest else _basename(rel)
                score = len(src)
        elif rel == src:
            out = dest + "/" + _basename(rel) if dest else _basename(rel)
            score = len(src) + 1000
        elif rel.startswith(src + "/"):
            tail = rel[len(src) + 1:]
            out = dest + "/" + tail if dest else tail
            score = len(src)

        # Longest / most specific rule wins, so python/impl/tensors beats
        # python/impl and an exact filename beats any directory rule.
        if out != None and score > best_score:
            best = out
            best_score = score

    return best

def _isaacsim_extension_impl(ctx):
    ext_name = ctx.attr.extension_name
    out_dir = ctx.actions.declare_directory(ctx.label.name)

    srcs = ctx.files.srcs
    rels = []
    for f in srcs:
        rel = _rel_within_ext(f.path, ext_name)
        if rel != None and not rel.endswith("/"):
            rels.append((f, rel))

    mapping = ctx.attr.mapping
    if not mapping:
        fail("%s: no premake mapping given; regenerate //bazel:source_exts.bzl" % ext_name)

    # add_ogn_dependencies copies a node directory under <module>/ogn/, in
    # addition to wherever the prebuild rules put it -- so this is a second
    # destination for the same file, not a different one.
    ogn_copies = []
    for f, rel in rels:
        for node_dir in ctx.attr.ogn_node_dirs:
            if rel.startswith(node_dir + "/"):
                ogn_copies.append((f, "{module}/ogn/{rel}".format(
                    module = ctx.attr.ogn_module,
                    rel = rel,
                )))

    copies = list(ogn_copies)
    manifest_file = None
    for f, rel in rels:
        dest = _dest_within_ext(rel, mapping)
        if dest == None:
            continue
        if dest == "config/extension.toml":
            manifest_file = f
        copies.append((f, dest))

    if not copies:
        fail("no source files matched source/*/%s/" % ext_name)
    if manifest_file == None:
        fail("%s has no config/extension.toml" % ext_name)

    # One shell action: mkdir the needed subdirs, then copy each file in.
    cmds = ["set -e", 'root="%s/%s"' % (out_dir.path, ext_name)]
    seen_dirs = {}
    for _, dest in copies:
        parts = dest.rsplit("/", 1)
        d = parts[0] if len(parts) == 2 else ""
        if d and d not in seen_dirs:
            seen_dirs[d] = True
            cmds.append('mkdir -p "$root/%s"' % d)
    cmds.append('mkdir -p "$root"')
    for f, dest in copies:
        cmds.append('cp -f "%s" "$root/%s"' % (f.path, dest))

    # Generated OmniGraph code. isaacsim_ogn_codegen already produced it as a
    # mirror of this extension's root, so it merges in as one copy. The node
    # definitions themselves are ordinary sources, placed by `mapping`.
    inputs = list(srcs)
    if ctx.file.ogn_generated:
        gen = ctx.file.ogn_generated
        inputs.append(gen)

        # -L: the generated tree is staged as symlinks, and an extension that
        # is half symlinks into another output path is not a self-contained
        # artifact.
        cmds.append('cp -RL "%s/%s/." "$root/"' % (gen.path, ext_name))

    # What the extension's own C++ sources produce: a carbonite plugin goes in
    # bin/, a pybind module beside the Python package that imports it. premake
    # decides which, per extension.
    for target, destination in ctx.attr.native_artifacts.items():
        for artifact in target[DefaultInfo].files.to_list():
            inputs.append(artifact)
            cmds += [
                'mkdir -p "$root/%s"' % destination,
                'cp -f "%s" "$root/%s/%s"' % (artifact.path, destination, artifact.basename),
            ]

    # A Python payload the extension vendors out of a packman package. premake
    # copies the package's omni/sensors directory into the extension's own
    # package directory, so `omni.sensors.generic_model_output` is imported as
    # `isaacsim.sensors.experimental.rtx.generic_model_output`; the paths below
    # are made relative to that same directory.
    for target, destination in ctx.attr.payloads.items():
        for f in target[DefaultInfo].files.to_list():
            marker = "/" + _PAYLOAD_ROOT + "/"
            idx = f.path.find(marker)
            if idx == -1:
                fail("%s: %s is not under %s/" % (ext_name, f.path, _PAYLOAD_ROOT))
            rel = f.path[idx + len(marker):]
            inputs.append(f)
            cmds += [
                'mkdir -p "$root/%s"' % (destination + "/" + rel).rsplit("/", 1)[0],
                'cp -f "%s" "$root/%s/%s"' % (f.path, destination, rel),
            ]

    # The vendored wheels the extension puts on sys.path. Upstream links a
    # directory built by pip into place here; //bazel:pip.bzl builds the same
    # directory out of pinned wheels.
    if ctx.file.pip_prebundle:
        bundle = ctx.file.pip_prebundle
        inputs.append(bundle)
        cmds += [
            'mkdir -p "$root/pip_prebundle"',
            'cp -RL "%s/." "$root/pip_prebundle/"' % bundle.path,
        ]

    ctx.actions.run_shell(
        outputs = [out_dir],
        inputs = inputs,
        command = "\n".join(cmds),
        mnemonic = "IsaacSimExtension",
        progress_message = "Building Kit extension %s from source" % ext_name,
    )

    return [
        DefaultInfo(
            files = depset([out_dir]),
            runfiles = ctx.runfiles(files = [out_dir]),
        ),
        IsaacSimExtensionInfo(
            extension_name = ext_name,
            manifest = manifest_file,
            root = out_dir,
        ),
    ]

isaacsim_extension = rule(
    implementation = _isaacsim_extension_impl,
    attrs = {
        "extension_name": attr.string(
            mandatory = True,
            doc = "Extension id, matching its source/*/<name> directory.",
        ),
        "mapping": attr.string_dict(
            mandatory = True,
            doc = "premake5.lua's prebuild rules: source path or glob -> " +
                  "destination directory, both relative to the extension root.",
        ),
        "ogn_generated": attr.label(
            allow_single_file = True,
            doc = "Optional isaacsim_ogn_codegen output for this extension.",
        ),
        "ogn_module": attr.string(
            doc = "Python module path the generated OmniGraph code belongs under.",
        ),
        "ogn_node_dirs": attr.string_list(
            doc = "Node directories add_ogn_dependencies copies under " +
                  "<module>/ogn/, on top of the prebuild rules.",
        ),
        "payloads": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "packman payload filegroup -> directory inside the extension.",
        ),
        "pip_prebundle": attr.label(
            allow_single_file = True,
            doc = "Optional pip_prebundle directory for this extension.",
        ),
        "native_artifacts": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Built shared library -> directory inside the extension.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The extension's source files.",
        ),
    },
    doc = "Assembles a pure-Python Kit extension from the Isaac Sim sources.",
)

def _isaacsim_extension_folder_impl(ctx):
    out_dir = ctx.actions.declare_directory(ctx.label.name)
    roots = [dep[IsaacSimExtensionInfo].root for dep in ctx.attr.exts]

    # Each input already contains exactly one <extension_name>/ directory, so
    # merging them yields a directory Kit accepts as a single --ext-folder.
    cmds = ["set -e", 'out="%s"' % out_dir.path, 'mkdir -p "$out"']
    for root in roots:
        cmds.append('cp -RL "%s/." "$out/"' % root.path)

    ctx.actions.run_shell(
        outputs = [out_dir],
        inputs = roots,
        command = "\n".join(cmds),
        mnemonic = "IsaacSimExtensionFolder",
        progress_message = "Collecting %d source-built Kit extensions" % len(roots),
    )
    return [DefaultInfo(
        files = depset([out_dir]),
        runfiles = ctx.runfiles(files = [out_dir]),
    )]

isaacsim_extension_folder = rule(
    implementation = _isaacsim_extension_folder_impl,
    attrs = {
        "exts": attr.label_list(
            providers = [IsaacSimExtensionInfo],
            mandatory = True,
            doc = "Source-built extensions to gather.",
        ),
    },
    doc = "Merges source-built extensions into one directory for --ext-folder.",
)
