"""Rules and macros for building GMP with Bazel."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("//bazel:mpn.bzl", "ALTERNATIVES", "CPU_PATHS")

# Default CPU variant per platform architecture (used when cpu="auto").
_AUTO_CPU = {
    "aarch64": "cora53",
    "x86_64": "k8",
}

# =========================================================================
# gmp_gen – run a GMP gen-* tool, capturing stdout to a file
# =========================================================================

def _gmp_gen_impl(ctx):
    args = [ctx.outputs.out.path, ctx.executable.tool.path] + ctx.attr.args
    ctx.actions.run(
        outputs = [ctx.outputs.out],
        inputs = [],
        executable = ctx.executable._redirect,
        arguments = args,
        tools = [ctx.executable.tool],
        mnemonic = "GmpGen",
        progress_message = "Generating %s" % ctx.outputs.out.short_path,
    )

    return [DefaultInfo(
        files = depset([ctx.outputs.out]),
    )]

gmp_gen = rule(
    implementation = _gmp_gen_impl,
    attrs = {
        "args": attr.string_list(
            doc = "Additional command-line arguments passed to the generator tool.",
            default = [],
        ),
        "out": attr.output(
            doc = "The output file to generate. The tool's stdout is captured into this file.",
            mandatory = True,
        ),
        "tool": attr.label(
            doc = "The GMP generator tool (e.g. gen-fac, gen-fib) whose stdout produces the output.",
            mandatory = True,
            executable = True,
            cfg = "exec",
        ),
        "_redirect": attr.label(
            default = Label("//bazel:redirect_stdout"),
            executable = True,
            cfg = "exec",
        ),
    },
)

# =========================================================================
# gmp_copy – symlink a file to a new path
# =========================================================================

def _gmp_copy_impl(ctx):
    ctx.actions.symlink(
        output = ctx.outputs.out,
        target_file = ctx.file.src,
    )

    return [DefaultInfo(
        files = depset([ctx.outputs.out]),
    )]

gmp_copy = rule(
    doc = "Creates a symlink to place a source file at a specific path in the output tree.",
    implementation = _gmp_copy_impl,
    attrs = {
        "out": attr.output(
            doc = "The output path for the symlink.",
            mandatory = True,
        ),
        "src": attr.label(
            doc = "The source file to symlink.",
            mandatory = True,
            allow_single_file = True,
        ),
    },
)

# =========================================================================
# gmp_config_m4 – generate config.m4 from gmp-mparam.h + platform info
# =========================================================================

def _gmp_config_m4_impl(ctx):
    out = ctx.actions.declare_file("config.m4")
    ctx.actions.run(
        inputs = [ctx.file.mparam_h],
        outputs = [out],
        executable = ctx.executable._tool,
        arguments = [
            out.path,
            ctx.attr.arch,
            ctx.attr.os,
            ctx.file.mparam_h.path,
        ],
        mnemonic = "GmpConfigM4",
        progress_message = "Generating config.m4 for %s/%s" % (ctx.attr.arch, ctx.attr.os),
    )
    return DefaultInfo(files = depset([out]))

gmp_config_m4 = rule(
    doc = "Generates config.m4 from gmp-mparam.h and platform parameters.",
    implementation = _gmp_config_m4_impl,
    attrs = {
        "arch": attr.string(
            doc = "TODO",
            mandatory = True,
        ),
        "mparam_h": attr.label(
            doc = "TODO",
            mandatory = True,
            allow_single_file = True,
        ),
        "os": attr.string(
            doc = "TODO",
            mandatory = True,
        ),
        "_tool": attr.label(
            default = Label("//bazel:gen_config_m4"),
            executable = True,
            cfg = "exec",
        ),
    },
)

# =========================================================================
# gmp_mpn_multi – wrapper sources for multi-function generic C files
# =========================================================================

def _gmp_mpn_op_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.operation + ".c")
    ctx.actions.write(
        output = out,
        content = "#define OPERATION_{op} 1\n#include \"{src}\"\n".format(
            op = ctx.attr.operation,
            src = ctx.attr.src,
        ),
    )
    return [DefaultInfo(files = depset([out]))]

_gmp_mpn_op = rule(
    doc = "Generates a wrapper .c file that `#define`s `OPERATION_<name>` and `#include`s a multi-function MPN source.",
    implementation = _gmp_mpn_op_impl,
    attrs = {
        "operation": attr.string(
            doc = "The MPN operation name (e.g. `and_n`). Used to define `OPERATION_<name>` in the wrapper.",
            mandatory = True,
        ),
        "src": attr.string(
            doc = "Path to the multi-function MPN source file to `#include` (e.g. `mpn/generic/logops_n.c`).",
            mandatory = True,
        ),
    },
)

def gmp_mpn_multi(*, name, src, operations):
    """Generates wrapper sources for a multi-function MPN source file.

    Args:
        name: The name of the collection target.
        src: The path to the multi-function MPN source file.
        operations: List of operation names to generate wrappers for.

    Returns:
        The list of generated source labels.
    """
    targets = []
    for op in operations:
        tgt = "_mpn_" + op
        _gmp_mpn_op(
            name = tgt,
            operation = op,
            src = src,
        )
        targets.append(":" + tgt)

    native.filegroup(
        name = name,
        srcs = targets,
    )

    return targets

# =========================================================================
# gmp_mpn_m4 – select and compile a single MPN function
# =========================================================================

# Functions to skip when assembly already provides them as extra entrypoints.
# Mirrors configure.ac lines 3474-3479.
_SKIP_WHEN_ASM_PROVIDES = {
    "pre_divrem_1": "divrem_1",
    "pre_mod_1": "mod_1",
}

def _mpn_rel_path(f, workspace_root):
    """Strips workspace root + 'mpn/' prefix to get the relative path under mpn/."""
    prefix = workspace_root + "/mpn/" if workspace_root else "mpn/"
    if f.path.startswith(prefix):
        return f.path[len(prefix):]
    return None

def _find_asm_source(operation, asm_files, search_dirs, workspace_root):
    """Finds the .asm file that provides an operation, searching dirs in priority order."""
    by_rel = {}
    for f in asm_files:
        rel = _mpn_rel_path(f, workspace_root)
        if rel:
            by_rel[rel] = f

    candidates = [operation] + ALTERNATIVES.get(operation, [])
    for d in search_dirs:
        for candidate in candidates:
            key = d + "/" + candidate + ".asm"
            if key in by_rel:
                return by_rel[key]
    return None

def _find_generic_source(operation, generic_files, workspace_root):
    """Finds the generic .c file for an operation."""
    candidates = [operation] + ALTERNATIVES.get(operation, [])
    for f in generic_files:
        rel = _mpn_rel_path(f, workspace_root)
        if rel:
            basename = rel.split("/")[-1].removesuffix(".c")
            if basename in candidates:
                return f
    return None

def _should_skip(operation, asm_files, search_dirs, workspace_root):
    """Check if a function should be skipped because assembly provides it as an extra entrypoint."""
    provider = _SKIP_WHEN_ASM_PROVIDES.get(operation)
    if not provider:
        return False
    by_rel = {}
    for f in asm_files:
        rel = _mpn_rel_path(f, workspace_root)
        if rel:
            by_rel[rel] = True
    for d in search_dirs:
        if d + "/" + provider + ".asm" in by_rel:
            return True
    return False

def _resolve_search_dirs(arch, cpu, os):
    """Compute the mpn subdirectory search path from arch + cpu variant."""
    if os == "windows":
        return []
    if cpu != "auto" and cpu in CPU_PATHS:
        return CPU_PATHS[cpu]
    return CPU_PATHS.get(_AUTO_CPU.get(arch, ""), [arch] if arch != "generic" else [])

def _gmp_mpn_m4_impl(ctx):
    operation = ctx.attr.operation
    arch = ctx.attr.arch
    cpu = ctx.attr.cpu[BuildSettingInfo].value
    workspace_root = ctx.label.workspace_root

    search_dirs = _resolve_search_dirs(arch, cpu, ctx.attr.os)

    if _should_skip(operation, ctx.files.asm_srcs, search_dirs, workspace_root):
        out = ctx.actions.declare_file("mpn/" + operation + ".c")
        ctx.actions.write(out, "")
        return DefaultInfo(files = depset([out]))

    asm_src = _find_asm_source(operation, ctx.files.asm_srcs, search_dirs, workspace_root)
    if asm_src:
        out = ctx.actions.declare_file("mpn/" + operation + ".s")

        ruledir = workspace_root
        if ctx.label.package:
            ruledir = ruledir + "/" + ctx.label.package
        gendir_mpn = ctx.var["GENDIR"] + "/" + ruledir + "/mpn"

        ctx.actions.run(
            inputs = ctx.files.asm_srcs + ctx.files.m4_deps,
            outputs = [out],
            executable = ctx.executable._redirect,
            arguments = [
                out.path,
                ctx.executable._m4.path,
                "-I",
                gendir_mpn,
                "-I",
                ruledir,
                "-DHAVE_CONFIG_H",
                "-D__GMP_WITHIN_GMP",
                "-DOPERATION_" + operation,
                "-DPIC",
                asm_src.path,
            ],
            tools = [ctx.executable._m4],
            mnemonic = "GmpM4",
            progress_message = "M4 %s -> %s" % (asm_src.short_path, out.short_path),
        )
        return DefaultInfo(files = depset([out]))

    generic_src = _find_generic_source(operation, ctx.files.generic_srcs, workspace_root)
    if generic_src:
        out = ctx.actions.declare_file("mpn/" + operation + ".c")
        prefix = workspace_root
        if ctx.label.package:
            prefix = prefix + "/" + ctx.label.package
        rel_path = generic_src.path.removeprefix(prefix + "/")
        ctx.actions.write(
            output = out,
            content = "#define OPERATION_{op} 1\n#include \"{src}\"\n".format(
                op = operation,
                src = rel_path,
            ),
        )
        return DefaultInfo(files = depset([out]))

    out = ctx.actions.declare_file("mpn/" + operation + ".c")
    ctx.actions.write(out, "")
    return DefaultInfo(files = depset([out]))

gmp_mpn_m4 = rule(
    doc = "Selects and compiles a single MPN function from architecture-specific assembly or generic C.",
    implementation = _gmp_mpn_m4_impl,
    attrs = {
        "arch": attr.string(
            doc = "Target architecture (x86_64, aarch64, generic).",
            mandatory = True,
        ),
        "asm_srcs": attr.label_list(
            doc = "All .asm files for the target architecture.",
            allow_files = [".asm"],
        ),
        "cpu": attr.label(
            doc = "CPU variant string_flag.",
            mandatory = True,
        ),
        "generic_srcs": attr.label_list(
            doc = "All generic .c source files.",
            allow_files = [".c"],
        ),
        "m4_deps": attr.label_list(
            doc = "M4 include files and config.m4.",
            allow_files = True,
        ),
        "operation": attr.string(
            doc = "The MPN operation name.",
            mandatory = True,
        ),
        "os": attr.string(
            doc = "Target OS (linux, macos, windows).",
            mandatory = True,
        ),
        "_m4": attr.label(
            default = Label("@m4//:m4"),
            executable = True,
            cfg = "exec",
        ),
        "_redirect": attr.label(
            default = Label("//bazel:redirect_stdout"),
            executable = True,
            cfg = "exec",
        ),
    },
)

# =========================================================================
# gmp_native_defs – extract HAVE_NATIVE_* from .asm PROLOGUE declarations
# =========================================================================

def _filter_asm_by_search_dirs(asm_files, search_dirs, workspace_root):
    """Filter .asm files to only those directly in the selected search directories."""
    filtered = []
    for f in asm_files:
        rel = _mpn_rel_path(f, workspace_root)
        if rel:
            dir_part = rel.rsplit("/", 1)[0] if "/" in rel else ""
            if dir_part in search_dirs:
                filtered.append(f)
    return filtered

def _gmp_native_defs_impl(ctx):
    out = ctx.actions.declare_file("native_defs.h")

    search_dirs = _resolve_search_dirs(
        ctx.attr.arch,
        ctx.attr.cpu[BuildSettingInfo].value,
        ctx.attr.os,
    )
    selected = _filter_asm_by_search_dirs(
        ctx.files.asm_srcs,
        search_dirs,
        ctx.label.workspace_root,
    )

    if not selected:
        ctx.actions.write(out, "/* No native assembly functions. */\n")
        return DefaultInfo(files = depset([out]))

    ctx.actions.run(
        inputs = selected,
        outputs = [out],
        executable = ctx.executable._extract_natives,
        arguments = [out.path] + [f.path for f in selected],
        mnemonic = "GmpExtractNatives",
        progress_message = "Extracting HAVE_NATIVE defines",
    )
    return DefaultInfo(files = depset([out]))

gmp_native_defs = rule(
    doc = "Extracts HAVE_NATIVE_mpn_* defines from assembly PROLOGUE declarations.",
    implementation = _gmp_native_defs_impl,
    attrs = {
        "arch": attr.string(
            doc = "Target architecture.",
            mandatory = True,
        ),
        "asm_srcs": attr.label_list(
            doc = "Architecture-specific .asm files.",
            allow_files = [".asm"],
        ),
        "cpu": attr.label(
            doc = "CPU variant string_flag.",
            mandatory = True,
        ),
        "os": attr.string(
            doc = "Target OS (linux, macos, windows).",
            mandatory = True,
        ),
        "_extract_natives": attr.label(
            default = Label("//bazel:extract_natives"),
            executable = True,
            cfg = "exec",
        ),
    },
)
