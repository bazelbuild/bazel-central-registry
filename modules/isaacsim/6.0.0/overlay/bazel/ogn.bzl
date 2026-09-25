"""Generate OmniGraph node code from the `.ogn` definitions in the source tree.

An OmniGraph node is declared in a `.ogn` file (JSON, Apache-2.0, in this
repository) from which a database class is generated -- `OgnDope.ogn` becomes
`OgnDopeDatabase.py`, the interface the node's own Python implementation binds
against. Upstream runs that generator during its premake build; extensions whose
generated files are missing load and then fail on first use, which is why they
were previously taken as prebuilts instead of built here.

The generator ships inside the prebuilt `omni.graph.tools` extension, which this
module already downloads, and it is plain Python. Two things about how it locates
its own configuration decide the layout `kit_ogn_toolchain` builds:

  * it finds the OmniGraph ABI version to target by globbing for a directory
    named `omni.graph.core*` beside its own extension root, and
  * it finds its attribute-union configuration by walking up its own path for a
    directory named exactly `omni.graph.tools`.

Both use the *resolved* path of the generator module, so a symlink farm named by
package id -- which is what Kit itself wants -- does not satisfy either. The
toolchain therefore copies both extensions into one tree under their bare names.
Getting this wrong is silent: the generator emits a database with
`TARGET_VERSION = (0, 0, 0)` instead of the real ABI version and says only that
it is "using default".
"""

def _repo_root(files):
    """The repository root shared by a filegroup's files, or None if empty."""
    for f in files:
        short = f.short_path
        rel = short.split("/", 2)[2] if short.startswith("../") else short
        if f.path.endswith(rel):
            return f.path[:-len(rel)]
    return None

def _kit_ogn_toolchain_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name)

    tools_root = _repo_root(ctx.files.tools)
    core_root = _repo_root(ctx.files.core)
    if not tools_root or not core_root:
        fail("omni.graph.tools and omni.graph.core must both be non-empty")

    ctx.actions.run_shell(
        outputs = [out],
        inputs = ctx.files.tools + ctx.files.core,
        command = "\n".join([
            "set -e",
            'out="%s"' % out.path,
            'mkdir -p "$out/omni.graph.tools" "$out/omni.graph.core"',
            # -L, because the inputs are symlinks into their own repositories
            # and the generator resolves its own path: copying the links would
            # put it right back where it cannot see its sibling.
            'cp -RL "%s." "$out/omni.graph.tools/"' % tools_root,
            'cp -RL "%s." "$out/omni.graph.core/"' % core_root,
        ]),
        mnemonic = "KitOgnToolchain",
        progress_message = "Assembling the OmniGraph node generator",
    )
    return [DefaultInfo(files = depset([out]))]

kit_ogn_toolchain = rule(
    implementation = _kit_ogn_toolchain_impl,
    attrs = {
        "core": attr.label(
            allow_files = True,
            mandatory = True,
            doc = "The prebuilt omni.graph.core extension.",
        ),
        "tools": attr.label(
            allow_files = True,
            mandatory = True,
            doc = "The prebuilt omni.graph.tools extension.",
        ),
    },
    doc = "Lays the OmniGraph node generator out the way it expects to find itself.",
)

def _isaacsim_ogn_codegen_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name)

    toolchain = ctx.file.toolchain
    python = ctx.file.python
    config_root = _repo_root(ctx.files.config)
    if not config_root:
        fail("the node generator's configuration directory is empty")

    # The generator is given a mirror of the extension root to write into: it
    # records a node's icon as a path relative to a directory named after the
    # extension, and refuses to generate at all if it cannot find one.
    # ogn_helpers.lua puts the pieces at <ext>/<module>/ogn, <ext>/ogn/icons and
    # <ext>/ogn/docs; mirroring that means the merge is a single copy.
    ext_root = "$out/%s" % ctx.attr.extension_name
    ogn_root = "%s/%s/ogn" % (ext_root, ctx.attr.module)
    cmds = [
        "set -e",
        'out="%s"' % out.path,
        'mkdir -p "{ogn}/tests/usd" "{ext}/ogn/docs" "{ext}/ogn/icons" "$out/tags"'.format(
            ext = ext_root,
            ogn = ogn_root,
        ),
    ]
    generator = "%s/omni.graph.tools/omni/graph/tools/generate_node.py" % toolchain.path
    for ogn in ctx.files.ogn_files:
        cmds.append(" ".join([
            '"%s"' % python.path,
            '"%s"' % generator,
            '--configDir "%s"' % (config_root + "kit/dev/ogn/config"),
            '--extension "%s"' % ctx.attr.extension_name,
            '--module "%s"' % ctx.attr.module.replace("/", "."),
            '--python "%s"' % ogn_root,
            '--tests "%s/tests"' % ogn_root,
            '--usdPath "%s/tests/usd"' % ogn_root,
            '--unwritable "%s"' % ogn_root,
            '--docs "%s/ogn/docs"' % ext_root,
            '--icons "%s/ogn/icons"' % ext_root,
            '--intermediate "$out/tags"',
            '--nodeFile "%s"' % ogn.path,
        ]))

    # The tag files only exist so premake can tell whether a node is up to date;
    # Bazel already knows.
    cmds.append('rm -rf "$out/tags"')

    ctx.actions.run_shell(
        outputs = [out],
        inputs = depset(
            ctx.files.ogn_files + ctx.files.node_srcs + ctx.files.config +
            ctx.files.python_runtime + [python, toolchain],
        ),
        command = "\n".join(cmds),
        mnemonic = "IsaacSimOgn",
        progress_message = "Generating %d OmniGraph node(s) for %s" % (
            len(ctx.files.ogn_files),
            ctx.attr.extension_name,
        ),
    )
    return [DefaultInfo(files = depset([out]))]

def _isaacsim_ogn_cpp_impl(ctx):
    # The C++ side of the same generator: one database header per node, which
    # the hand-written node implementation includes by bare name. They are
    # declared individually rather than as a directory so that a cc_library can
    # put the directory on the include path.
    headers = []
    for ogn in ctx.files.ogn_files:
        base = ogn.basename[:-len(".ogn")]
        headers.append(ctx.actions.declare_file("{dir}/{base}Database.h".format(
            base = base,
            dir = ctx.attr.include_dir,
        )))

    include_root = headers[0].dirname
    config_root = _repo_root(ctx.files.config)
    generator = "%s/omni.graph.tools/omni/graph/tools/generate_node.py" % ctx.file.toolchain.path

    cmds = ["set -e", 'mkdir -p "%s" "%s/tags"' % (include_root, include_root)]
    for ogn in ctx.files.ogn_files:
        cmds.append(" ".join([
            '"%s"' % ctx.file.python.path,
            '"%s"' % generator,
            '--configDir "%s"' % (config_root + "kit/dev/ogn/config"),
            '--extension "%s"' % ctx.attr.extension_name,
            '--module "%s"' % ctx.attr.module.replace("/", "."),
            '--cpp "%s"' % include_root,
            '--intermediate "%s/tags"' % include_root,
            '--nodeFile "%s"' % ogn.path,
        ]))
    cmds.append('rm -rf "%s/tags"' % include_root)

    ctx.actions.run_shell(
        outputs = headers,
        inputs = depset(
            ctx.files.ogn_files + ctx.files.node_srcs + ctx.files.config +
            ctx.files.python_runtime + [ctx.file.python, ctx.file.toolchain],
        ),
        command = "\n".join(cmds),
        mnemonic = "IsaacSimOgnCpp",
        progress_message = "Generating %d OmniGraph node header(s) for %s" % (
            len(headers),
            ctx.attr.extension_name,
        ),
    )
    return [DefaultInfo(files = depset(headers))]

isaacsim_ogn_cpp = rule(
    implementation = _isaacsim_ogn_cpp_impl,
    attrs = {
        "config": attr.label(allow_files = True, mandatory = True),
        "extension_name": attr.string(mandatory = True),
        "include_dir": attr.string(
            mandatory = True,
            doc = "Package-relative directory the headers are written to.",
        ),
        "module": attr.string(mandatory = True),
        "node_srcs": attr.label_list(allow_files = True),
        "ogn_files": attr.label_list(allow_files = [".ogn"], mandatory = True),
        "python": attr.label(allow_single_file = True, mandatory = True),
        "python_runtime": attr.label(allow_files = True, mandatory = True),
        "toolchain": attr.label(allow_single_file = True, mandatory = True),
    },
    doc = "Generates the C++ database headers for an extension's OmniGraph nodes.",
)

isaacsim_ogn_codegen = rule(
    implementation = _isaacsim_ogn_codegen_impl,
    attrs = {
        "config": attr.label(
            allow_files = True,
            mandatory = True,
            doc = "The kernel's dev/ogn/config directory.",
        ),
        "extension_name": attr.string(
            mandatory = True,
            doc = "Extension id, e.g. \"isaacsim.replicator.writers\".",
        ),
        "module": attr.string(
            mandatory = True,
            doc = "Python module path of the extension, e.g. " +
                  "\"isaacsim/replicator/writers\".",
        ),
        "node_srcs": attr.label_list(
            allow_files = True,
            doc = "Everything else in the node directories -- a .ogn refers to " +
                  "its icon and category configuration by relative path, so they " +
                  "have to be there when it is read.",
        ),
        "ogn_files": attr.label_list(
            allow_files = [".ogn"],
            mandatory = True,
            doc = "The node definitions to generate from.",
        ),
        "python": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "Interpreter to run the generator with -- the CPython the Kit " +
                  "kernel bundles, so the generated code targets the same one " +
                  "Kit will import it with.",
        ),
        "python_runtime": attr.label(
            allow_files = True,
            mandatory = True,
            doc = "That interpreter's own tree, as action inputs.",
        ),
        "toolchain": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "kit_ogn_toolchain tree.",
        ),
    },
    doc = "Runs the OmniGraph node generator over an extension's .ogn files.",
)
