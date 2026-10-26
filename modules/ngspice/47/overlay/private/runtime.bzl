"""Declared native runtime assembly and launcher generation for ngspice."""

visibility("//...")

_CODE_MODELS = ["spice2poly", "analog", "digital", "xtradev", "xtraevt", "table", "tlines"]

def _runtime_impl(ctx):
    output = ctx.actions.declare_directory(ctx.label.name)
    spinit = ctx.actions.declare_file(ctx.label.name + "_spinit")
    substitutions = {}
    for model in _CODE_MODELS:
        # SPICE_LIB_DIR is supplied by the launcher or embedding application.
        # Quoting the complete filename preserves spaces in a relocated tree.
        substitutions["@XSPICEINIT@ codemodel @pkglibdir@/%s.cm" % model] = (
            "" if ctx.attr.xspice else "* "
        ) + 'codemodel "$SPICE_LIB_DIR/../../lib/ngspice/%s.cm"' % model
    substitutions["@pkglibdir@"] = "lib/ngspice"
    ctx.actions.expand_template(
        template = ctx.file.spinit_template,
        output = spinit,
        substitutions = substitutions,
    )
    entries = {"share/ngspice/scripts/spinit": (spinit, "0644")}
    assets = dict(ctx.attr.assets)
    if ctx.attr.xspice:
        assets.update(ctx.attr.xspice_assets)
    for target, destination in assets.items():
        files = target[DefaultInfo].files.to_list()
        if len(files) != 1:
            fail("Runtime asset must contain exactly one file: %s" % target.label)
        if destination in entries:
            fail("Duplicate runtime destination: %s" % destination)
        entries[destination] = (files[0], "0644")
    if ctx.file.cli:
        entries["bin/ngspice"] = (ctx.file.cli, "0755")
    modules = ctx.files.code_models + ctx.files.cosimulation_modules
    if modules and not ctx.attr.xspice:
        fail("XSPICE modules must be omitted when xspice is disabled")
    for file in modules:
        destination = "lib/ngspice/" + file.basename
        if destination in entries:
            fail("Duplicate runtime destination: %s" % destination)
        entries[destination] = (file, "0755")
    arguments = ctx.actions.args()
    arguments.add(output.path)
    inputs = []
    for destination in sorted(entries):
        file, mode = entries[destination]
        inputs.append(file)
        arguments.add_all([destination, mode, file.path])
    ctx.actions.run(
        executable = ctx.executable._tool,
        arguments = [arguments],
        inputs = depset(inputs),
        outputs = [output],
        mnemonic = "NgspiceRuntime",
        progress_message = "Assembling ngspice runtime %s" % ctx.label,
    )
    return [DefaultInfo(files = depset([output]), runfiles = ctx.runfiles(files = [output]))]

_runtime = rule(
    implementation = _runtime_impl,
    attrs = {
        "assets": attr.label_keyed_string_dict(allow_files = True),
        "cli": attr.label(allow_single_file = True),
        "code_models": attr.label_list(allow_files = True),
        "cosimulation_modules": attr.label_list(allow_files = True),
        "spinit_template": attr.label(allow_single_file = True, mandatory = True),
        "xspice": attr.bool(default = True),
        "xspice_assets": attr.label_keyed_string_dict(allow_files = True),
        "_tool": attr.label(default = Label(":runtime_tool"), executable = True, cfg = "exec"),
    },
)

def ngspice_runtime(name, cli = None, code_models = [], cosimulation_modules = [], xspice = True, source_root = "src", **kwargs):
    """Assemble the installed runtime tree as this target's single output.

    Args:
      name: Target and output directory name.
      cli: Optional target-platform executable to install as bin/ngspice.
      code_models: Native module outputs with their upstream .cm basenames.
      cosimulation_modules: Optional ivlng.so and ivlng.vpi module outputs.
      xspice: Whether to install XSPICE assets; supports select().
      source_root: Path to upstream src within the calling package.
      **kwargs: Common rule attributes such as visibility and constraints.
    """
    scripts = "share/ngspice/scripts/"
    verilog = source_root + "/xspice/verilog/"
    vhdl = source_root + "/xspice/vhdl/"
    xspice_assets = {
        verilog + "vlnggen": scripts + "vlnggen",
        vhdl + "ghnggen": scripts + "ghnggen",
    }
    for filename in ["verilator_shim.cpp", "verilator_main.cpp"]:
        xspice_assets[verilog + filename] = scripts + "src/" + filename
    for filename in ["ghdl_shim.h", "ghdl_shim.c", "ghdl_vpi.c"]:
        xspice_assets[vhdl + filename] = scripts + "src/" + filename
    for filename in ["cosim.h", "miftypes.h", "cmtypes.h"]:
        xspice_assets[source_root + "/include/ngspice/" + filename] = scripts + "src/ngspice/" + filename
    for filename in ["coroutine.h", "coroutine_cosim.h", "coroutine_shim.h"]:
        xspice_assets[verilog + filename] = scripts + "src/ngspice/" + filename
    _runtime(
        name = name,
        cli = cli,
        code_models = code_models,
        cosimulation_modules = cosimulation_modules,
        xspice = xspice,
        assets = {
            source_root + "/setplot": scripts + "setplot",
            source_root + "/spectrum": scripts + "spectrum",
        },
        xspice_assets = xspice_assets,
        spinit_template = source_root + "/spinit.in",
        **kwargs
    )

def _launcher_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".sh")
    runtime = ctx.file.runtime
    if runtime.short_path.startswith("../"):
        runfile = runtime.short_path[3:]
    else:
        runfile = ctx.workspace_name + "/" + runtime.short_path
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = output,
        substitutions = {"@INSTALL_RUNFILE@": runfile},
        is_executable = True,
    )
    return [DefaultInfo(files = depset([output]))]

ngspice_launcher = rule(
    implementation = _launcher_impl,
    attrs = {
        "runtime": attr.label(allow_single_file = True, mandatory = True),
        "_template": attr.label(default = Label(":ngspice.sh.in"), allow_single_file = True),
    },
)
