"""The few generated files of the binutils build that are not plain templates."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

visibility(["//..."])

# --- install_dirs ------------------------------------------------------------------

def _flag(ctx, name):
    return getattr(ctx.attr, name)[BuildSettingInfo].value

def _cstring(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'

def _install_directories(ctx):
    """The GNU directory variables, derived from the flags as configure does."""
    prefix = _flag(ctx, "prefix")
    exec_prefix = _flag(ctx, "exec_prefix") or prefix
    libdir = _flag(ctx, "libdir") or exec_prefix + "/lib"
    tooldir = exec_prefix + "/" + ctx.attr.triple
    return struct(
        prefix = prefix,
        exec_prefix = exec_prefix,
        bindir = _flag(ctx, "bindir") or exec_prefix + "/bin",
        libdir = libdir,
        datadir = prefix + "/share",
        tooldir = tooldir,
        scriptdir = tooldir + "/lib",
        # bfd/configure.ac:133-138, --with-separate-debug-dir.
        debugdir = _flag(ctx, "with_separate_debug_dir") or libdir + "/debug",
        sysroot = _flag(ctx, "with_sysroot"),
    )

def _install_dirs_impl(ctx):
    dirs = _install_directories(ctx)
    values = {
        "BINDIR": _cstring(dirs.bindir),
        "DEBUGDIR": _cstring(dirs.debugdir),
        "LIBDIR": _cstring(dirs.libdir),
        "LOCALEDIR": _cstring(dirs.datadir + "/locale"),
        "SCRIPTDIR": _cstring(dirs.scriptdir),
        "TARGET_SYSTEM_ROOT": _cstring(dirs.sysroot),
        "TOOLBINDIR": _cstring(dirs.tooldir + "/bin"),
    }
    defines = [name + "=" + values[name] for name in ctx.attr.defines]
    if "TARGET_SYSTEM_ROOT" in ctx.attr.defines and dirs.sysroot:
        # ld/configure.ac:78-85: a sysroot under the prefix is relocatable.
        for root in (dirs.prefix, dirs.exec_prefix):
            if dirs.sysroot == root or dirs.sysroot.startswith(root + "/"):
                defines.append("TARGET_SYSTEM_ROOT_RELOCATABLE")
                break
    return [CcInfo(compilation_context = cc_common.create_compilation_context(defines = depset(defines)))]

_DIRECTORY_FLAGS = {
    "bindir": attr.label(
        default = Label("//:bindir"),
        providers = [BuildSettingInfo],
        doc = "The --bindir flag; `$(bindir)`, BINDIR.",
    ),
    "exec_prefix": attr.label(
        default = Label("//:exec_prefix"),
        providers = [BuildSettingInfo],
        doc = "The --exec-prefix flag; `$(exec_prefix)`, under which $(tooldir) lives.",
    ),
    "libdir": attr.label(
        default = Label("//:libdir"),
        providers = [BuildSettingInfo],
        doc = "The --libdir flag; `$(libdir)`, LIBDIR.",
    ),
    "prefix": attr.label(
        default = Label("//:prefix"),
        providers = [BuildSettingInfo],
        doc = "The --prefix flag; `$(prefix)`, the default for the other directories.",
    ),
    "triple": attr.string(
        mandatory = True,
        doc = "The platform's canonical triple, which names $(tooldir).",
    ),
    "with_separate_debug_dir": attr.label(
        default = Label("//:with_separate_debug_dir"),
        providers = [BuildSettingInfo],
        doc = "The --with-separate-debug-dir flag; DEBUGDIR.",
    ),
    "with_sysroot": attr.label(
        default = Label("//:with_sysroot"),
        providers = [BuildSettingInfo],
        doc = "The --with-sysroot flag; TARGET_SYSTEM_ROOT, and TARGET_SYSTEM_ROOT_RELOCATABLE when it lies under $(exec_prefix).",
    ),
}

install_dirs = rule(
    implementation = _install_dirs_impl,
    doc = """\
The directory `-D` flags of the Makefiles, as a `CcInfo` of defines.

bfd/Makefile.am passes BINDIR and LIBDIR to every file and DEBUGDIR to
dwarf2.c; ld/Makefile.am passes BINDIR, TOOLBINDIR, SCRIPTDIR and
TARGET_SYSTEM_ROOT to ldmain.c and ldfile.c; every program gets LOCALEDIR.
`defines` names which of those this instance provides.
""",
    attrs = _DIRECTORY_FLAGS | {
        "defines": attr.string_list(
            mandatory = True,
            doc = "Which of BINDIR, LIBDIR, DEBUGDIR, TOOLBINDIR, SCRIPTDIR, LOCALEDIR and TARGET_SYSTEM_ROOT to provide.",
        ),
    },
)

# --- flag_defines --------------------------------------------------------------------

def _flag_defines_impl(ctx):
    defines = []
    if ctx.attr.enabled:
        for target, define in ctx.attr.flags.items():
            value = target[BuildSettingInfo].value
            if value:
                defines.append(define + "=" + _cstring(value))
    return [CcInfo(compilation_context = cc_common.create_compilation_context(defines = depset(defines)))]

flag_defines = rule(
    implementation = _flag_defines_impl,
    doc = """\
`AC_DEFINE_UNQUOTED(NAME, "$withval")` for string options that are only
defined when given: each flag with a non-empty value becomes `-DNAME="value"`.
`enabled` lets a platform select() switch the whole set off, as gas does for
the RISC-V options on other architectures.
""",
    attrs = {
        "enabled": attr.bool(
            default = True,
            doc = "Whether any define is produced; False yields an empty set.",
        ),
        "flags": attr.label_keyed_string_dict(
            mandatory = True,
            providers = [BuildSettingInfo],
            doc = "Flag -> define name.",
        ),
    },
)

# --- policy_defines ------------------------------------------------------------------

def _policy_defines_impl(ctx):
    value = ctx.attr.flag[BuildSettingInfo].value
    if value in ctx.attr.auto:
        value = ctx.attr.default
    if value not in ctx.attr.values:
        fail("{}: {} = {} has no defines in `values`".format(ctx.label, ctx.attr.flag.label, value))
    return [CcInfo(compilation_context = cc_common.create_compilation_context(defines = depset(ctx.attr.values[value])))]

policy_defines = rule(
    implementation = _policy_defines_impl,
    doc = """\
The defines of a yes/no/auto configure option whose "auto" answer the
target decides (-z relro, -z separate-code, the hash style, ...).

The flag's value picks an entry of `values`; the values listed in `auto`
pick the entry named by `default` instead, which is a select() over the
platform data.  The result is a `CcInfo` of defines for `deps` or
`implementation_deps`, the same way `install_dirs` is consumed.
""",
    attrs = {
        "auto": attr.string_list(
            doc = "The flag values meaning 'the target's default', e.g. [\"auto\"] or [\"\"].",
        ),
        "default": attr.string(
            mandatory = True,
            doc = "The target's default as a key of `values`; `select_default()` from platforms.bzl.",
        ),
        "flag": attr.label(
            mandatory = True,
            providers = [BuildSettingInfo],
            doc = "The option's string_flag.",
        ),
        "values": attr.string_list_dict(
            mandatory = True,
            doc = "Flag value or default -> the `NAME=value` defines it means.",
        ),
    },
)

# --- bugurl ------------------------------------------------------------------------

def _bugurl_impl(ctx):
    url = ctx.attr.url[BuildSettingInfo].value
    return [BuildSettingInfo(value = "<" + url + ">" if url else "")]

bugurl = rule(
    implementation = _bugurl_impl,
    doc = "ACX_BUGURL (config/acx.m4): --with-bugurl's value wrapped in angle brackets, as REPORT_BUGS_TO.",
    attrs = {
        "url": attr.label(
            mandatory = True,
            providers = [BuildSettingInfo],
            doc = "The --with-bugurl flag; empty disables the bug report URL.",
        ),
    },
    provides = [BuildSettingInfo],
)

# --- tool_output -------------------------------------------------------------------

def _tool_output_impl(ctx):
    args = ctx.actions.args()
    args.add("--stdin", ctx.file.src)
    args.add("--stdout", ctx.outputs.out)
    args.add("--")
    args.add(ctx.executable.tool)
    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [args],
        inputs = [ctx.file.src],
        outputs = [ctx.outputs.out],
        tools = [ctx.executable.tool],
        mnemonic = "GenerateTable",
        progress_message = "Generating %s" % ctx.outputs.out.short_path,
        execution_requirements = {"supports-path-mapping": "1"},
    )

tool_output = rule(
    implementation = _tool_output_impl,
    doc = "`tool < src > out`: run a filter program the way its Makefile rule does, without a shell.",
    attrs = {
        "out": attr.output(
            mandatory = True,
            doc = "The file TOOL's standard output is written to.",
        ),
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The file TOOL reads on standard input.",
        ),
        "tool": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
            doc = "The generator built from the tree, e.g. //opcodes:s390-mkopc.",
        ),
        "_process_wrapper": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//tools:process_wrapper"),
            doc = "Does the redirection; see tools/process_wrapper.cc.",
        ),
    },
)

# --- ld_emulations -----------------------------------------------------------------

def _ld_emulations_impl(ctx):
    dirs = _install_directories(ctx)
    genscripts = ctx.file.genscripts

    # ld/Makefile.am:385-392: GENSCRIPTS and the e%.c rule, once per emulation.
    # Each runs in its own directory because every one writes ldscripts/.
    # The script and its srcdir are given as `${pwd}/...`, which the wrapper
    # expands to the action's root, so they stay valid after the `--cwd`.
    sources = []
    scripts = []
    for emul in ctx.attr.emulations:
        outdir = "_emulations/" + emul
        source = ctx.actions.declare_file(outdir + "/e" + emul + ".c")
        ldscripts = ctx.actions.declare_directory(outdir + "/ldscripts")
        args = ctx.actions.args()
        args.add("--path", ctx.executable.sed, format = "%s/..")
        args.add_all("--cwd", [ldscripts], expand_directories = False, format_each = "%s/..")
        args.add("--")
        args.add("sh")
        args.add(genscripts, format = "${pwd}/%s")
        args.add(genscripts.dirname, format = "${pwd}/%s")  # srcdir
        args.add_all([
            dirs.libdir,
            dirs.prefix,
            dirs.exec_prefix,
            ctx.attr.triple,  # host
            ctx.attr.triple,  # target
            ctx.attr.triple,  # target_alias
            "",  # DEPDIR: no dependency tracking
            _flag(ctx, "with_lib_path"),
            " ".join(ctx.attr.libpath),
            " ".join(ctx.attr.native_lib_dirs),
            "yes" if dirs.sysroot else "no",
            "yes" if _flag(ctx, "enable_initfini_array") else "no",
            emul,
            ctx.attr.tdirs.get(emul, ctx.attr.triple),
        ])
        ctx.actions.run(
            executable = ctx.executable._process_wrapper,
            arguments = [args],
            outputs = [source, ldscripts],
            inputs = ctx.files.srcs,
            tools = [ctx.executable.sed],
            mnemonic = "LdGenscripts",
            progress_message = "Generating ld emulation %s" % emul,
            execution_requirements = {"supports-path-mapping": "1"},
        )
        sources.append(source)
        scripts.append(ldscripts)

    return [
        DefaultInfo(files = depset(sources)),
        OutputGroupInfo(ldscripts = depset(scripts)),
    ]

ld_emulations = rule(
    implementation = _ld_emulations_impl,
    doc = """\
Run `genscripts.sh` for every emulation of the platform.

Produces the `e*.c` emulation sources (`$(EMULATION_OFILES)`) and the
`ldscripts/` directories (output group `ldscripts`) that `make install`
puts under `$(tooldir)/lib`.

genscripts.sh is a POSIX shell program: it sources the emulparams/,
emultempl/ and scripttempl/ files, which emit C and linker scripts through
heredocs and parameter expansion (some 20k lines across the three
directories, rewritten in nearly every release), and the generated sources
are too large and too dependent on the install-directory flags to ship
pre-generated.  So this is the one action that runs `sh`.  It does so
through `//tools:process_wrapper` rather than `run_shell`: the wrapper
enters the emulation's output directory, puts GNU sed from the `sed`
module first on PATH, and execs `sh genscripts.sh ...`.  The script itself
calls sed, cat, cmp, rm, mkdir, sort, head, tail, grep, tr and touch by
name; everything but sed comes from the base system, the same environment
any `sh_binary` assumes.
""",
    attrs = _DIRECTORY_FLAGS | {
        "emulations": attr.string_list(
            mandatory = True,
            doc = "$(EMULATION_OFILES), without the e prefix and .o suffix, in order.",
        ),
        "enable_initfini_array": attr.label(
            default = Label("//:enable_initfini_array"),
            providers = [BuildSettingInfo],
            doc = "The --enable-initfini-array flag, exported to the scripts as `enable_initfini_array`.",
        ),
        "genscripts": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "ld/genscripts.sh; its directory is the srcdir the scripts source from.",
        ),
        "libpath": attr.string_list(
            mandatory = True,
            doc = "@EMULATION_LIBPATH@.",
        ),
        "native_lib_dirs": attr.string_list(
            mandatory = True,
            doc = "@NATIVE_LIB_DIRS@.",
        ),
        "sed": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("@sed//:sed"),
            doc = "GNU sed, which the templates require; its directory is put first on PATH.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "genscripts.sh and everything it sources: emulparams/, emultempl/, scripttempl/, genscrba.sh.",
        ),
        "tdirs": attr.string_dict(
            mandatory = True,
            doc = "The tool directory (tdir_*) of the emulations whose directory is not `triple`.",
        ),
        "with_lib_path": attr.label(
            default = Label("//:with_lib_path"),
            providers = [BuildSettingInfo],
            doc = "The --with-lib-path flag; LIB_PATH, the default search directories written into the scripts.",
        ),
        "_process_wrapper": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//tools:process_wrapper"),
            doc = "Enters the output directory and sets PATH before running sh; see tools/process_wrapper.cc.",
        ),
    },
)
