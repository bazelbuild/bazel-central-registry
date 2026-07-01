"""GHDL utility rules for VHDL standard library compilation and testing."""

# ===========================================================================
# Backend transition
# ===========================================================================

_BACKEND = str(Label("//:backend"))

def _backend_transition_impl(_settings, attr):
    return {_BACKEND: attr.backend}

_backend_transition = transition(
    implementation = _backend_transition_impl,
    inputs = [],
    outputs = [_BACKEND],
)

def _ghdl_with_backend_impl(ctx):
    actual = ctx.attr.actual[0]
    default_info = actual[DefaultInfo]
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(output = executable, target_file = default_info.files_to_run.executable)
    return [
        DefaultInfo(
            executable = executable,
            runfiles = default_info.default_runfiles,
        ),
    ]

ghdl_with_backend = rule(
    doc = """Builds a GHDL target with a specific backend.

Applies a transition to set the `//:backend` flag, then forwards the
executable and runfiles from the underlying target. Use this to create
named targets like `ghdl_mcode` or `ghdl_llvm_jit` that don't require
passing `--//:backend=` on the command line.
""",
    implementation = _ghdl_with_backend_impl,
    attrs = {
        "actual": attr.label(
            mandatory = True,
            executable = True,
            cfg = _backend_transition,
        ),
        "backend": attr.string(
            mandatory = True,
            values = ["mcode", "llvm-jit"],
            doc = "Backend to transition to.",
        ),
    },
    executable = True,
)

# ===========================================================================
# VHDL standard library compilation
# ===========================================================================

def _preprocess_action(ctx, vhdl_std_gen, std, src, out):
    """Run the preprocessor on a single VHDL file."""
    args = ctx.actions.args()
    args.add("preprocess")
    args.add("--std=" + std)
    args.add(src, format = "--input=%s")
    args.add(out, format = "--output=%s")

    ctx.actions.run(
        executable = vhdl_std_gen,
        arguments = [args],
        inputs = [src],
        outputs = [out],
        mnemonic = "VhdlPreprocess",
        progress_message = "Preprocessing %s for VHDL-%s" % (src.short_path, std),
    )

def _copy_action(ctx, src, out):
    """Copy a file via symlink."""
    ctx.actions.symlink(output = out, target_file = src)

def _args_map_dirname(value):
    return value.dirname

def _arg_map_lib_root(value):
    """lib_root contains std/vXX/ and ieee/vXX/ — ghdl's -P flag needs this."""
    return value.dirname.rsplit("/", 2)[0]

def _vhdl_std_libs_impl(ctx):
    vhdl_std_gen = ctx.executable._vhdl_std_gen
    ghdl = ctx.executable.ghdl
    std = ctx.attr.std

    src_prefix = ctx.label.name + "/src"
    lib_prefix = ctx.label.name

    all_outputs = []

    # Step 1: Preprocess and copy source files into the output tree.
    # The directory structure mirrors upstream: <name>/src/{std,ieee}/vXX/
    std_compiled_srcs = []
    for src in ctx.files.std_srcs:
        out = ctx.actions.declare_file(src_prefix + "/std/v" + std + "/" + src.basename)
        _preprocess_action(ctx, vhdl_std_gen, std, src, out)
        std_compiled_srcs.append(out)
        all_outputs.append(out)

    ieee_compiled_srcs = []
    for src in ctx.files.ieee_srcs:
        out = ctx.actions.declare_file(src_prefix + "/ieee/v" + std + "/" + src.basename)
        _preprocess_action(ctx, vhdl_std_gen, std, src, out)
        ieee_compiled_srcs.append(out)
        all_outputs.append(out)

    ieee_extra_compiled = []
    for src in ctx.files.ieee_extra_srcs:
        out = ctx.actions.declare_file(src_prefix + "/ieee/v" + std + "/" + src.basename)
        _copy_action(ctx, src, out)
        ieee_extra_compiled.append(out)
        all_outputs.append(out)

    ieee_relaxed_compiled = []
    for src in ctx.files.ieee_relaxed_srcs:
        out = ctx.actions.declare_file(src_prefix + "/ieee/v" + std + "/" + src.basename)
        _copy_action(ctx, src, out)
        ieee_relaxed_compiled.append(out)
        all_outputs.append(out)

    synopsys_compiled = []
    for src in ctx.files.synopsys_srcs:
        out = ctx.actions.declare_file(src_prefix + "/ieee/v" + std + "/" + src.basename)
        _copy_action(ctx, src, out)
        synopsys_compiled.append(out)
        all_outputs.append(out)

    synopsys_pp_compiled = []
    for src in ctx.files.synopsys_pp_srcs:
        out = ctx.actions.declare_file(src_prefix + "/ieee/v" + std + "/" + src.basename)
        _preprocess_action(ctx, vhdl_std_gen, std, src, out)
        synopsys_pp_compiled.append(out)
        all_outputs.append(out)

    # Step 2: Compile STD library.
    std_cf = ctx.actions.declare_file(lib_prefix + "/std/v" + std + "/std-obj" + std + ".cf")
    all_outputs.append(std_cf)

    std_args = ctx.actions.args()
    std_args.add("compile-lib")
    std_args.add(ghdl, format = "--ghdl=%s")
    std_args.add_all([std_cf], format_each = "--workdir=%s", map_each = _args_map_dirname)
    std_args.add("--flag=--std=" + std)
    std_args.add("--flag=--bootstrap")
    std_args.add("--flag=--work=std")
    std_args.add_all(std_compiled_srcs)

    ctx.actions.run(
        executable = vhdl_std_gen,
        arguments = [std_args],
        inputs = [ghdl] + std_compiled_srcs,
        outputs = [std_cf],
        mnemonic = "GhdlCompileStd",
        progress_message = "Compiling VHDL STD library (v%s)" % std,
    )

    # Step 3: Compile IEEE library + Synopsys in a single action.
    # Both write to the same .cf file, so they must be one action.
    # The vhdl_std_gen compile-lib command is invoked multiple times
    # using the "++" separator (first for IEEE, then for Synopsys with -fsynopsys).
    ieee_cf = ctx.actions.declare_file(lib_prefix + "/ieee/v" + std + "/ieee-obj" + std + ".cf")
    all_outputs.append(ieee_cf)

    ieee_all_srcs = ieee_compiled_srcs + ieee_extra_compiled
    synopsys_all = synopsys_compiled + synopsys_pp_compiled

    # Build a single chained action: ieee core ++ relaxed ++ synopsys.
    # All groups write to the same .cf file.
    ieee_args = ctx.actions.args()
    ieee_args.add("compile-lib")
    ieee_args.add(ghdl, format = "--ghdl=%s")
    ieee_args.add_all([ieee_cf], format_each = "--workdir=%s", map_each = _args_map_dirname)
    ieee_args.add_all([std_cf], format_each = "--lib-path=%s", map_each = _arg_map_lib_root)
    ieee_args.add("--flag=--std=" + std)
    ieee_args.add("--flag=--work=ieee")
    ieee_args.add_all(ieee_all_srcs)

    all_ieee_inputs = ieee_all_srcs

    if ieee_relaxed_compiled:
        ieee_args.add("++")
        ieee_args.add("compile-lib")
        ieee_args.add(ghdl, format = "--ghdl=%s")
        ieee_args.add_all([ieee_cf], format_each = "--workdir=%s", map_each = _args_map_dirname)
        ieee_args.add_all([std_cf], format_each = "--lib-path=%s", map_each = _arg_map_lib_root)
        ieee_args.add("--flag=--std=" + std)
        ieee_args.add("--flag=--work=ieee")
        ieee_args.add("--flag=-frelaxed-rules")
        ieee_args.add_all(ieee_relaxed_compiled)
        all_ieee_inputs = all_ieee_inputs + ieee_relaxed_compiled

    if synopsys_all:
        ieee_args.add("++")
        ieee_args.add("compile-lib")
        ieee_args.add(ghdl, format = "--ghdl=%s")
        ieee_args.add_all([ieee_cf], format_each = "--workdir=%s", map_each = _args_map_dirname)
        ieee_args.add_all([std_cf], format_each = "--lib-path=%s", map_each = _arg_map_lib_root)
        ieee_args.add("--flag=--std=" + std)
        ieee_args.add("--flag=--work=ieee")
        ieee_args.add("--flag=-fsynopsys")
        ieee_args.add_all(synopsys_all)
        all_ieee_inputs = all_ieee_inputs + synopsys_all

    ctx.actions.run(
        executable = vhdl_std_gen,
        arguments = [ieee_args],
        inputs = [ghdl, std_cf] + all_ieee_inputs + std_compiled_srcs,
        outputs = [ieee_cf],
        mnemonic = "GhdlCompileIeee",
        progress_message = "Compiling VHDL IEEE library (v%s)" % std,
    )

    return [DefaultInfo(files = depset(all_outputs))]

vhdl_std_libs = rule(
    implementation = _vhdl_std_libs_impl,
    doc = """Compiles GHDL VHDL standard libraries for a given VHDL standard version.

Preprocesses VHDL source files to filter version-specific markers (e.g. `--V87`,
`--V08`, `--START-V19`), then compiles them into STD and IEEE work libraries
using the GHDL binary. Produces both the compiled library metadata (`.cf` files)
and the preprocessed source files as outputs.

The compilation is split into up to three groups within a single IEEE action:
  1. Core IEEE sources (and any non-preprocessed extras like math, UPF)
  2. Relaxed sources compiled with `-frelaxed-rules` (VITAL2000 in v08/v19)
  3. Synopsys sources compiled with `-fsynopsys`
""",
    attrs = {
        "ghdl": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            doc = "The GHDL binary used to compile VHDL libraries.",
        ),
        "ieee_extra_srcs": attr.label_list(
            allow_files = [".vhdl"],
            doc = "IEEE sources not needing preprocessing (math, UPF, VITAL).",
        ),
        "ieee_relaxed_srcs": attr.label_list(
            allow_files = [".vhdl"],
            doc = "IEEE sources compiled with -frelaxed-rules (VITAL2000 in v08).",
        ),
        "ieee_srcs": attr.label_list(
            allow_files = [".vhdl"],
            doc = "IEEE sources needing version preprocessing.",
        ),
        "std": attr.string(
            mandatory = True,
            values = ["87", "93", "08", "19"],
            doc = "VHDL standard version to compile for.",
        ),
        "std_srcs": attr.label_list(
            mandatory = True,
            allow_files = [".vhdl"],
            doc = "STD library sources (textio, env). Preprocessed for the target version.",
        ),
        "synopsys_pp_srcs": attr.label_list(
            allow_files = [".vhdl"],
            doc = "Synopsys sources needing preprocessing.",
        ),
        "synopsys_srcs": attr.label_list(
            allow_files = [".vhdl"],
            doc = "Synopsys sources (compiled with -fsynopsys).",
        ),
        "_vhdl_std_gen": attr.label(
            default = "//bazel:vhdl_std_gen",
            executable = True,
            cfg = "exec",
        ),
    },
)

# ===========================================================================
# vhdl_test
# ===========================================================================

def _rlocationpath(ctx, f):
    """Return the rlocation path for a File."""
    if f.short_path.startswith("../"):
        return f.short_path[3:]
    return ctx.workspace_name + "/" + f.short_path

def _vhdl_test_impl(ctx):
    runner = ctx.executable._runner
    ghdl = ctx.executable.ghdl
    vhdl_files = ctx.files.srcs
    std = ctx.attr.std
    entity = ctx.attr.entity
    lib_files = ctx.files.vhdl_libs

    # Write an args file that the C++ test runner reads via runfiles.
    args_file = ctx.actions.declare_file(ctx.label.name + ".vhdl_test_args")
    args = ctx.actions.args()
    args.set_param_file_format("multiline")
    args.add(_rlocationpath(ctx, ghdl), format = "ghdl=%s")
    args.add(entity, format = "entity=%s")
    if std:
        args.add("--std=" + std, format = "flag=%s")

    if lib_files:
        for f in lib_files:
            if f.basename.endswith(".cf"):
                parts = _rlocationpath(ctx, f).rsplit("/", 3)
                args.add(parts[0], format = "prefix=%s")
                break

    for f in vhdl_files:
        args.add(_rlocationpath(ctx, f), format = "src=%s")

    ctx.actions.write(args_file, args)

    # Create a symlink to the runner binary — Bazel requires the test
    # executable to be created by the rule itself.
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(output = executable, target_file = runner)

    runfiles = ctx.runfiles(files = [ghdl, args_file] + vhdl_files + lib_files)
    runfiles = runfiles.merge(ctx.attr.ghdl[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge(ctx.attr._runner[DefaultInfo].default_runfiles)

    return [
        DefaultInfo(
            executable = executable,
            runfiles = runfiles,
        ),
        testing.TestEnvironment({
            "VHDL_TEST_ARGS_RLOCATIONPATH": _rlocationpath(ctx, args_file),
        }),
    ]

vhdl_test = rule(
    implementation = _vhdl_test_impl,
    doc = """Compiles and simulates VHDL source files using GHDL as a test.

Analyzes each source file with `ghdl -a`, then elaborates and runs the
specified top-level entity with `ghdl --elab-run`. The test passes if
simulation completes with exit code 0.

Uses a C++ test runner (`vhdl_test_runner`) that locates the GHDL binary
and source files via the Bazel runfiles library. Test parameters are
passed through an args file resolved at runtime.
""",
    attrs = {
        "entity": attr.string(
            mandatory = True,
            doc = "Top-level entity to elaborate and simulate.",
        ),
        "ghdl": attr.label(
            mandatory = True,
            executable = True,
            cfg = "target",
            doc = "The GHDL binary used to analyze and simulate VHDL files.",
        ),
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = [".vhdl", ".vhd"],
            doc = "VHDL source files to analyze. Compiled in order.",
        ),
        "std": attr.string(
            doc = "VHDL standard version (87, 93, 08, 19).",
        ),
        "vhdl_libs": attr.label_list(
            doc = "Compiled VHDL standard libraries.",
        ),
        "_runner": attr.label(
            default = "//bazel:vhdl_test_runner",
            executable = True,
            cfg = "target",
        ),
    },
    test = True,
)
