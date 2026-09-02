"""Shared rules and macros for building TeX Live components.

Header-collision rule of thumb: when upstream code does bare
`#include "config.h"`, list that package's own `config.h` in the
consuming cc_library's `hdrs` so source-relative search finds it before
any BCR dep's `-iquote` path. Otherwise use unique names (e.g.
`texlive-c-auto.h`) and namespaced includes (`<kpathsea/config.h>`).
"""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_shell//shell:sh_library.bzl", "sh_library")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

def force_include_copts(header):
    """Build a portable -include / /FI compiler flag select.

    Forces every translation unit to include @p header before its own
    source, used to inject autoconf-derived defines (HAVE_*, SIZEOF_*).

    Args:
        header: Header filename to force-include.

    Returns:
        A select() that yields the right flag for the active compiler.
    """
    return select({
        "@rules_cc//cc/compiler:clang-cl": ["/FI" + header],
        "@rules_cc//cc/compiler:msvc-cl": ["/FI" + header],
        "//conditions:default": ["-include", header],
    })

# Common compiler options for TeX Live code.
TEXLIVE_COPTS = select({
    "@rules_cc//cc/compiler:clang-cl": ["/w"],
    "@rules_cc//cc/compiler:msvc-cl": ["/w"],
    "//conditions:default": ["-w"],
})

TEXLIVE_LOCAL_DEFINES = ["HAVE_CONFIG_H"] + select({
    "@platforms//os:windows": ["WIN32"],
    "//conditions:default": [],
})

# Hoisted once so hot-loop macros (web_utility etc.) don't rebuild
# Label objects / default-arg lists on every call.
_MANUAL_TAGS = ["manual"]
_KPATHSEA_LABEL = Label("//texk/kpathsea")
_WEB2C_LIB_LABEL = Label("//texk/web2c:web2c_lib")
_WEB2C_COMMON_DEFINES = Label("//texk/web2c/web2c:common.defines")

def _mktex_default_select(short):
    """`MAKE_TEX_<SHORT>_BY_DEFAULT=1` when //:mktex<short>_default is True."""
    macro = "MAKE_TEX_" + short.upper() + "_BY_DEFAULT"
    return select({
        Label("//:mktex" + short + "_enabled"): [macro + "=1"],
        "//conditions:default": [macro + "=0"],
    })

# Public defines propagated by //texk/kpathsea to every consumer.
# Upstream defines these via `AC_DEFINE_UNQUOTED` in kpathsea's
# `c-auto.in`, so every file that transitively pulls in a kpathsea
# header (engines AND non-engine consumers like dvipsk/dviljk/xdvik/
# xdvipsk) sees them. We move them to kpathsea's `defines` (public,
# propagated) instead of a `local_defines` on each consumer.
#
# * MAKE_TEX_*_BY_DEFAULT: kpathsea program-enabled defaults for
#   auto-generating missing files at runtime. Read by
#   `kpse_set_program_enabled()` callers.
# * MAKE_OMEGA_{OCP,OFM}_BY_DEFAULT: hardcoded to 0 — omega no longer
#   builds by default and hitex.w gates on the macro.
def _kpathsea_mktex_defines():
    defines = [
        "MAKE_OMEGA_OCP_BY_DEFAULT=0",
        "MAKE_OMEGA_OFM_BY_DEFAULT=0",
    ]
    for short in ("fmt", "mf", "pk", "tex", "tfm"):
        defines = defines + _mktex_default_select(short)
    return defines

KPATHSEA_MKTEX_DEFINES = _kpathsea_mktex_defines()

# `local_defines` shared by every TeX-engine cc_library (and its
# cc_binary wrapper, which textually includes lib/texmfmp.c via
# <engine>extra.c). Any engine bypassing this constant silently loses
# IPC / NO_DUMP_SHARE — don't inline `TEXLIVE_LOCAL_DEFINES` on engine
# targets, use `TEX_ENGINE_DEFINES` instead.
#
# * IPC: gated on `//:enable_ipc` (default True). Consumed by
#   texk/web2c/lib/texmfmp.c's `#if defined(TeX) && defined(IPC)` block.
# * NO_DUMP_SHARE: emitted when `//:enable_dump_share` is False (the
#   flag is inverted in the upstream configure — `--disable-dump-share`
#   makes fmt/base dump files architecture-dependent).
TEX_ENGINE_DEFINES = TEXLIVE_LOCAL_DEFINES + select({
    Label("//:ipc_enabled"): ["IPC"],
    "//conditions:default": [],
}) + select({
    Label("//:dump_share_enabled"): [],
    "//conditions:default": ["NO_DUMP_SHARE"],
})

# Force-include //bazel:msvc_shim.h on MSVC compiles to neutralise
# GCC-only `__attribute__((...))` syntax that cl.exe can't parse. The
# shim defines `__attribute__(x)` as empty when neither __GNUC__ nor
# __clang__ is set. Empty on other compilers — they handle the
# attributes natively.
MSVC_ATTRIBUTE_SHIM_COPTS = select({
    "@rules_cc//cc/compiler:clang-cl": ["/FImsvc_shim.h"],
    "@rules_cc//cc/compiler:msvc-cl": ["/FImsvc_shim.h"],
    "//conditions:default": [],
})

# Flex-generated scanners hard-include <unistd.h>; -DYY_NO_UNISTD_H is
# flex's documented escape for systems without it (MSVC). MinGW ships
# <unistd.h> so the escape only fires for cl.exe / clang-cl.
FLEX_MSVC_DEFINES = select({
    "@rules_cc//cc/compiler:clang-cl": ["YY_NO_UNISTD_H"],
    "@rules_cc//cc/compiler:msvc-cl": ["YY_NO_UNISTD_H"],
    "//conditions:default": [],
})

# Upstream texk/*/Makefile.am hardcodes -DUNIX because Autotools never
# builds these on MSVC. The macro gates Unix-only includes (<unistd.h>,
# <sys/types.h>) and POSIX file-mode handling. MinGW ships <unistd.h>
# and is the historical "Windows-but-POSIX-ish" target, so UNIX stays
# on there; only cl.exe / clang-cl skip it.
TEXK_UNIX_DEFINES = select({
    "@rules_cc//cc/compiler:clang-cl": [],
    "@rules_cc//cc/compiler:msvc-cl": [],
    "//conditions:default": ["UNIX"],
})

# splitup fixed args: -i emits #include "<base>.h", -l 65000 caps each
# split C file's line count (matches upstream texk/web2c/Makefile.am).
_SPLITUP_FIXED_ARGS = ["-i", "-l", "65000"]

# libm is implicit on Windows (CRT) and on macOS (built into libSystem).
MATH_LINKOPTS = select({
    "@platforms//os:macos": [],
    "@platforms//os:windows": [],
    "//conditions:default": ["-lm"],
})

def _wrapper_args(ctx, chdir = None, env = {}, quiet = False):
    """Build argument list for the process_wrapper tool.

    Returns an Args object with env/chdir/quiet flags set. Callers must
    add any --cat/--stdout flags, then "--" followed by the command.
    """
    args = ctx.actions.args()
    for k, v in env.items():
        args.add("--env", "{}={}".format(k, v))
    if chdir:
        args.add("--chdir", chdir)
    if quiet:
        args.add("--quiet")
    return args

def _texlive_env(extra = {}):
    """Standard env vars for TeX Live tools to suppress kpathsea search."""
    env = {"TEXMFCNF": "/nonexistent"}
    env.update(extra)
    return env

# =============================================================================
# tangle_web rule
# =============================================================================

def _tangle_web_impl(ctx):
    # `tangle <web> [ch]` writes <base>.p (and <base>.pool, when requested)
    # to CWD, where <base> is the .web filename stem after any program
    # override. We chdir into the declared output directory so the
    # side-effect .p/.pool land where Bazel expects them, then pass full
    # paths to the input files so tangle does not have to do its own
    # WEBINPUTS lookup.
    prog = ctx.attr.program if ctx.attr.program else ctx.file.web.basename.rsplit(".", 1)[0]
    p_out = ctx.actions.declare_file(prog + ".p")
    outputs = [p_out]
    pool_out = None
    if ctx.attr.emit_pool:
        pool_out = ctx.actions.declare_file(prog + ".pool")
        outputs.append(pool_out)

    # Tangle derives the output base from the .web argument's filename. When
    # the caller wants a different program name (e.g. pdftex from a webfile
    # named differently), symlink the source under the desired name before
    # invoking tangle.
    web_for_tangle = ctx.file.web
    inputs = [ctx.file.web]
    if ctx.attr.program and ctx.file.web.basename != prog + ".web":
        renamed = ctx.actions.declare_file(prog + ".web")
        ctx.actions.symlink(output = renamed, target_file = ctx.file.web)
        web_for_tangle = renamed
        inputs = [renamed]

    args = _wrapper_args(ctx, chdir = p_out.dirname, env = _texlive_env(), quiet = True)
    args.add("--")
    args.add(ctx.executable.tangle_tool)
    args.add(web_for_tangle)
    if ctx.file.ch:
        inputs.append(ctx.file.ch)
        args.add(ctx.file.ch)

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [args],
        inputs = inputs,
        outputs = outputs,
        tools = [ctx.executable.tangle_tool],
        mnemonic = "TangleWeb",
        progress_message = "Tangling %{input}",
    )
    return [DefaultInfo(files = depset(outputs))]

tangle_web = rule(
    doc = """\
Runs Knuth's `tangle` on a WEB source file to produce Pascal (.p) output,
and optionally a .pool file (needed by TeX engines for string-pool init).

WEB is a literate programming system where `.web` files contain interwoven
documentation and Pascal source. The `tangle` tool extracts the Pascal,
optionally applying changes from a `.ch` (change) file. The output `.p` file
is then converted to C by the `web2c_convert` rule.
""",
    implementation = _tangle_web_impl,
    attrs = {
        "ch": attr.label(
            doc = "Optional change file (.ch) applied on top of the WEB source.",
            allow_single_file = [".ch"],
        ),
        "emit_pool": attr.bool(
            doc = "If true, also declare the .pool string-pool output.",
            default = False,
        ),
        "program": attr.string(
            doc = "Output program name; defaults to the .web file stem.",
        ),
        "tangle_tool": attr.label(
            doc = "The tangle binary. Override for bootstrapping.",
            default = Label("//texk/web2c:tangle"),
            executable = True,
            cfg = "exec",
        ),
        "web": attr.label(
            doc = "The WEB source file (.web) to tangle.",
            allow_single_file = [".web"],
            mandatory = True,
        ),
        "_process_wrapper": attr.label(
            default = Label("//bazel:process_wrapper"),
            executable = True,
            cfg = "exec",
        ),
    },
)

# =============================================================================
# web2c_convert rule
# =============================================================================

def _web2c_convert_impl(ctx):
    c_outs = [ctx.actions.declare_file(f) for f in ctx.attr.outs if f.endswith(".c")]
    h_outs = [ctx.actions.declare_file(f) for f in ctx.attr.outs if f.endswith(".h")]
    outputs = c_outs + h_outs
    out_dir = outputs[0].dirname
    prog = ctx.attr.program

    p_files = [
        f
        for f in ctx.files.src
        if f.basename.endswith(".p") or f.basename.endswith(".pin")
    ]
    if len(p_files) != 1:
        fail("web2c_convert: expected exactly one .p file in {}, got {}".format(
            ctx.attr.src.label,
            [f.basename for f in ctx.files.src],
        ))
    p_file = p_files[0]

    # For TeX engines:
    #   - web2c emits `#include "<prog>coerce.h"` into the C stream and
    #     writes a <prog>coerce.h file alongside. splitup keys off that
    #     `#include` marker, so the name in the C MUST be <prog>coerce.h.
    #     We have web2c write its raw output into a `web2c_raw/` subdir to
    #     avoid clashing with the final, post-append <prog>coerce.h.
    #   - <prog>d.h is just touched empty by convert.sh — we emit a stub.
    coerce_final = None
    coerce_intermediate = None
    d_h_final = None
    if ctx.attr.is_tex_engine:
        for h in h_outs:
            if h.basename == prog + "coerce.h":
                coerce_final = h
            elif h.basename == prog + "d.h":
                d_h_final = h
        if coerce_final:
            coerce_intermediate = ctx.actions.declare_file(
                "web2c_raw/" + prog + "coerce.h",
            )

    # Step 1: Concatenate defines + source into a single .p file.
    combined = ctx.actions.declare_file(prog + "_combined.p")
    concat_args = _wrapper_args(ctx, env = _texlive_env())
    for f in ctx.files.defines:
        concat_args.add("--cat", f)
    concat_args.add("--cat", p_file)
    concat_args.add("--stdout", combined)
    # No command after `--` → process_wrapper concat-only mode.

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [concat_args],
        inputs = [p_file] + ctx.files.defines,
        outputs = [combined],
        mnemonic = "Web2CCat",
        progress_message = "Preparing %{input} for web2c",
    )

    # Step 2: Run web2c on the combined input.
    # For simple programs:  web2c -h<hfile> -c<prog>          writes <prog>.h
    # For TeX-like engines: web2c -t -h<hfile> -c<prog>coerce writes
    #   <prog>coerce.h and emits `#include "<prog>coerce.h"` in the C
    #   stream (which splitup keys off). We chdir into a `web2c_raw/`
    #   subdirectory so that intermediate file does NOT collide with the
    #   final post-append <prog>coerce.h declared in h_outs.
    web2c_out = ctx.actions.declare_file(prog + "_web2c.c")
    if ctx.attr.is_tex_engine and coerce_intermediate:
        web2c_chdir = coerce_intermediate.dirname
    else:
        web2c_chdir = out_dir
    web2c_args = _wrapper_args(ctx, chdir = web2c_chdir, env = _texlive_env())
    web2c_args.add("--cat", combined)
    web2c_args.add("--stdout", web2c_out)
    web2c_args.add("--")
    web2c_args.add(ctx.executable._web2c)
    web2c_args.add("-h" + ctx.attr.header)
    if ctx.attr.is_tex_engine:
        web2c_args.add("-t")
    web2c_args.add("-c" + prog + ("coerce" if ctx.attr.is_tex_engine else ""))

    # For TeX engines the web2c step emits the raw coerce header; the splitup
    # step emits the .c files; the final coerce.h and the empty d.h are built
    # in post-processing actions below.
    if ctx.attr.is_tex_engine:
        web2c_h_outputs = [coerce_intermediate] if coerce_intermediate else []
    else:
        web2c_h_outputs = h_outs
    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [web2c_args],
        inputs = [combined],
        outputs = [web2c_out] + web2c_h_outputs,
        tools = [ctx.executable._web2c],
        mnemonic = "Web2CTranslate",
        progress_message = "Translating %{input} Pascal to C",
    )

    # Step 3: Run fixwrites.
    fixwrites_out = ctx.actions.declare_file(prog + "_fixwrites.c")
    fix_args = _wrapper_args(ctx, env = _texlive_env())
    fix_args.add("--cat", web2c_out)
    fix_args.add("--stdout", fixwrites_out)
    fix_args.add("--")
    fix_args.add(ctx.executable._fixwrites)
    if ctx.attr.is_tex_engine:
        fix_args.add("-t")
    fix_args.add(prog)

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [fix_args],
        inputs = [web2c_out],
        outputs = [fixwrites_out],
        tools = [ctx.executable._fixwrites],
        mnemonic = "Web2CFixwrites",
        progress_message = "Fixwrites %{input}",
    )

    # Step 4: Run splitup (for large engines) or rename for simple programs.
    # splitup writes the numbered .c chunks AND <prog>d.h (the defines
    # header — #undef TRIP, #define STAT, engine-specific macros, etc.).
    if ctx.attr.use_splitup:
        split_outputs = list(c_outs)
        if d_h_final:
            split_outputs.append(d_h_final)
        split_args = _wrapper_args(ctx, chdir = out_dir, env = _texlive_env())
        split_args.add("--cat", fixwrites_out)
        split_args.add("--")
        split_args.add(ctx.executable._splitup)
        split_args.add_all(_SPLITUP_FIXED_ARGS)
        split_args.add(prog)

        ctx.actions.run(
            executable = ctx.executable._process_wrapper,
            arguments = [split_args],
            inputs = [fixwrites_out],
            outputs = split_outputs,
            tools = [ctx.executable._splitup],
            mnemonic = "Web2CSplitup",
            progress_message = "Splitting %{input}",
        )
    else:
        # Simple program: fixwrites output IS the final .c file.
        # The .h was already produced by web2c in step 2.
        ctx.actions.symlink(output = c_outs[0], target_file = fixwrites_out)

    # Step 5 (TeX engines only): finish the coerce header by appending
    # web2c/coerce.h to the raw header web2c produced in step 2.
    if ctx.attr.is_tex_engine and coerce_final and coerce_intermediate:
        if not ctx.file.coerce_tail:
            fail("web2c_convert: is_tex_engine=True requires coerce_tail")
        tail_args = _wrapper_args(ctx, env = _texlive_env())
        tail_args.add("--cat", coerce_intermediate)
        tail_args.add("--cat", ctx.file.coerce_tail)
        tail_args.add("--stdout", coerce_final)

        # No command after `--` → process_wrapper concat-only mode.
        ctx.actions.run(
            executable = ctx.executable._process_wrapper,
            arguments = [tail_args],
            inputs = [coerce_intermediate, ctx.file.coerce_tail],
            outputs = [coerce_final],
            mnemonic = "Web2CCoerceAppend",
            progress_message = "Finishing " + prog + "coerce.h",
        )

    return [DefaultInfo(files = depset(outputs))]

web2c_convert = rule(
    doc = """\
Converts a Pascal (.p) file to C using the web2c toolchain.

Runs a pipeline: `cat defines src | web2c | fixwrites > output.c`, or for
large engines: `... | fixwrites | splitup` which splits into numbered chunks.
""",
    implementation = _web2c_convert_impl,
    attrs = {
        "coerce_tail": attr.label(
            doc = "For TeX engines: a file appended to the raw coerce header " +
                  "to produce the final <prog>coerce.h. Typically web2c/coerce.h.",
            allow_single_file = True,
        ),
        "defines": attr.label_list(
            doc = "Define files prepended to the Pascal source (e.g., common.defines).",
            allow_files = True,
            default = [],
        ),
        "header": attr.string(
            doc = "Header name passed to web2c -h flag (e.g., 'cpascal.h' or 'texmfmp.h').",
            default = "cpascal.h",
        ),
        "is_tex_engine": attr.bool(
            doc = "If true, passes -t to fixwrites (for TeX-like engines).",
            default = False,
        ),
        "outs": attr.string_list(
            doc = "Output file names produced by the pipeline.",
            mandatory = True,
        ),
        "program": attr.string(
            doc = "Program name passed to web2c/fixwrites/splitup.",
            mandatory = True,
        ),
        "src": attr.label(
            doc = "Target producing the Pascal (.p / .pin) source file to " +
                  "convert; the rule selects the single .p/.pin output (so " +
                  "a `tangle_web` target with `emit_pool=True` also works).",
            allow_files = [".p", ".pin"],
            mandatory = True,
        ),
        "use_splitup": attr.bool(
            doc = "If true, pipes output through splitup for large programs.",
            default = False,
        ),
        "_fixwrites": attr.label(
            default = Label("//texk/web2c/web2c:fixwrites"),
            executable = True,
            cfg = "exec",
        ),
        "_process_wrapper": attr.label(
            default = Label("//bazel:process_wrapper"),
            executable = True,
            cfg = "exec",
        ),
        "_splitup": attr.label(
            default = Label("//texk/web2c/web2c:splitup"),
            executable = True,
            cfg = "exec",
        ),
        "_web2c": attr.label(
            default = Label("//texk/web2c/web2c:web2c_tool"),
            executable = True,
            cfg = "exec",
        ),
    },
)

# =============================================================================
# ctangle_cweb rule
# =============================================================================

def _ctangle_cweb_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out if ctx.attr.out else ctx.attr.name + ".c")
    inputs = [ctx.file.w_file] + ctx.files.extra_srcs

    extra_env = {"CWEBINPUTS": ctx.file.w_file.dirname}
    args = _wrapper_args(ctx, chdir = out.dirname, env = _texlive_env(extra_env), quiet = True)
    args.add("--")
    args.add(ctx.executable.ctangle_tool)
    args.add(ctx.file.w_file)
    if ctx.file.ch:
        inputs.append(ctx.file.ch)
        args.add(ctx.file.ch)
    args.add(out.basename)

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [args],
        inputs = inputs,
        outputs = [out],
        tools = [ctx.executable.ctangle_tool],
        mnemonic = "CTangleCWeb",
        progress_message = "CTangling %{input}",
    )
    return [DefaultInfo(files = depset([out]))]

ctangle_cweb = rule(
    doc = """\
Runs `ctangle` on a CWEB source file to produce C output.

CWEB is the C variant of Knuth's literate programming system. The `.w` file
contains interwoven documentation and C source. `ctangle` extracts the C,
optionally applying a change file.
""",
    implementation = _ctangle_cweb_impl,
    attrs = {
        "ch": attr.label(
            doc = "Optional change file (.ch) applied on top of the CWEB source.",
            allow_single_file = [".ch"],
        ),
        "ctangle_tool": attr.label(
            doc = "The ctangle binary. Override for bootstrapping.",
            default = Label("//texk/web2c:ctangle"),
            executable = True,
            cfg = "exec",
        ),
        "extra_srcs": attr.label_list(
            doc = "Additional source files needed by the CWEB file (e.g., included .w or .h files).",
            allow_files = True,
            default = [],
        ),
        "out": attr.string(
            doc = "Output filename. Defaults to `<name>.c`.",
        ),
        "w_file": attr.label(
            doc = "The CWEB source file (.w) to process.",
            allow_single_file = [".w"],
            mandatory = True,
        ),
        "_process_wrapper": attr.label(
            default = Label("//bazel:process_wrapper"),
            executable = True,
            cfg = "exec",
        ),
    },
)

# =============================================================================
# kpathsea_paths_h rule
# =============================================================================

def _kpathsea_paths_h_impl(ctx):
    out = ctx.actions.declare_file("paths.h")

    # Step 1: bsnl.awk joins backslash-continued lines.
    bsnl_out = ctx.actions.declare_file("_paths_bsnl.txt")
    bsnl_args = _wrapper_args(ctx)
    bsnl_args.add("--stdout", bsnl_out)
    bsnl_args.add("--")
    bsnl_args.add(ctx.executable._gawk)
    bsnl_args.add("-f", ctx.file.bsnl_awk)
    bsnl_args.add(ctx.file.cnf)

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [bsnl_args],
        inputs = [ctx.file.cnf, ctx.file.bsnl_awk],
        outputs = [bsnl_out],
        tools = [ctx.executable._gawk],
        mnemonic = "KpathseaBsnl",
    )

    # Step 2: Strip %-comments and whitespace (replaces sed in the
    # original Makefile). Awk script and input file are both passed
    # positionally to gawk; we deliberately avoid process_wrapper's
    # --cat stdin redirection because the Windows code path uses
    # freopen(stdin, ...) before _spawnvp, which gawk on Windows
    # crashes against (STATUS_STACK_BUFFER_OVERRUN).
    stripped_out = ctx.actions.declare_file("_paths_stripped.txt")
    strip_args = _wrapper_args(ctx)
    strip_args.add("--stdout", stripped_out)
    strip_args.add("--")
    strip_args.add(ctx.executable._gawk)
    strip_args.add("-f", ctx.file._strip_awk)
    strip_args.add(bsnl_out)

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [strip_args],
        inputs = [bsnl_out, ctx.file._strip_awk],
        outputs = [stripped_out],
        tools = [ctx.executable._gawk],
        mnemonic = "KpathseaStrip",
    )

    # Step 3: cnf-to-paths.awk produces #define lines. Pass both the
    # header comment and the stripped cnf as positional gawk input
    # files (no stdin redirection — same reason as Step 2). gawk
    # processes them in order, so the comment lines flow through first
    # followed by the cnf #defines.
    comment = ctx.actions.declare_file("_paths_comment.txt")
    ctx.actions.write(comment, "/* paths.h: Generated from texmf.cnf. */\n")

    cnf_args = _wrapper_args(ctx)
    cnf_args.add("--stdout", out)
    cnf_args.add("--")
    cnf_args.add(ctx.executable._gawk)
    cnf_args.add("-f", ctx.file.cnf_to_paths_awk)
    cnf_args.add(comment)
    cnf_args.add(stripped_out)

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [cnf_args],
        inputs = [comment, stripped_out, ctx.file.cnf_to_paths_awk],
        outputs = [out],
        tools = [ctx.executable._gawk],
        mnemonic = "KpathseaCnfToPaths",
    )

    return [DefaultInfo(files = depset([out]))]

kpathsea_paths_h = rule(
    doc = "Generates paths.h from texmf.cnf using bsnl.awk and cnf-to-paths.awk.",
    implementation = _kpathsea_paths_h_impl,
    attrs = {
        "bsnl_awk": attr.label(
            doc = "The bsnl.awk script that joins backslash-continued lines.",
            allow_single_file = True,
            mandatory = True,
        ),
        "cnf": attr.label(
            doc = "The texmf.cnf configuration file.",
            allow_single_file = True,
            mandatory = True,
        ),
        "cnf_to_paths_awk": attr.label(
            doc = "The cnf-to-paths.awk script that converts cnf to C #defines.",
            allow_single_file = True,
            mandatory = True,
        ),
        "_gawk": attr.label(
            default = Label("@gawk//:gawk"),
            executable = True,
            cfg = "exec",
        ),
        "_process_wrapper": attr.label(
            default = Label("//bazel:process_wrapper"),
            executable = True,
            cfg = "exec",
        ),
        "_strip_awk": attr.label(
            default = Label("//bazel:kpathsea_paths_strip_awk"),
            allow_single_file = True,
        ),
    },
)

# =============================================================================
# combine_changes rule
# =============================================================================

def _combine_changes_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    inputs = [ctx.file.web] + ctx.files.changes

    # WEBINPUTS lets tie look for the master web and `.ch0`/`.ch` files
    # without requiring callers to pass absolute paths. We list the
    # directories of all inputs so any include-resolution inside tie works.
    # kpathsea's ENV_SEP is ';' on Windows and ':' elsewhere — picking
    # the wrong one collapses the whole list into one bogus path.
    web_dirs = depset(
        [ctx.file.web.dirname] +
        [f.dirname for f in ctx.files.changes],
    )
    is_windows = ctx.target_platform_has_constraint(
        ctx.attr._windows_os[platform_common.ConstraintValueInfo],
    )
    sep = ";" if is_windows else ":"
    extra_env = {"WEBINPUTS": "." + sep + sep.join(web_dirs.to_list())}
    args = _wrapper_args(ctx, env = _texlive_env(extra_env), quiet = True)
    args.add("--")
    args.add(ctx.executable._tie)
    args.add("-c", out)
    args.add(ctx.file.web)
    args.add_all(ctx.files.changes)

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [args],
        inputs = inputs,
        outputs = [out],
        tools = [ctx.executable._tie],
        mnemonic = "TieCombine",
        progress_message = "Combining change files into %{output}",
    )
    return [DefaultInfo(files = depset([out]))]

combine_changes = rule(
    doc = """\
Runs `tie -c` to combine a master WEB file and a list of change (.ch) files
into a single combined change file. Used to prepare a `-final.ch` for each
TeX engine before tangling.
""",
    implementation = _combine_changes_impl,
    attrs = {
        "changes": attr.label_list(
            doc = "Change files (.ch) applied in order on top of the WEB.",
            allow_files = True,
            mandatory = True,
        ),
        "out": attr.string(
            doc = "Output filename (typically `<engine>-final.ch`).",
            mandatory = True,
        ),
        "web": attr.label(
            doc = "The master WEB file (.web) the changes apply to.",
            allow_single_file = [".web"],
            mandatory = True,
        ),
        "_process_wrapper": attr.label(
            default = Label("//bazel:process_wrapper"),
            executable = True,
            cfg = "exec",
        ),
        "_tie": attr.label(
            default = Label("//texk/web2c/web2c:tie"),
            executable = True,
            cfg = "exec",
        ),
        "_windows_os": attr.label(
            default = Label("@platforms//os:windows"),
            providers = [platform_common.ConstraintValueInfo],
        ),
    },
)

# =============================================================================
# makecpool_pool rule
# =============================================================================

def _makecpool_pool_impl(ctx):
    pool_files = [f for f in ctx.files.pool if f.basename.endswith(".pool")]
    if len(pool_files) != 1:
        fail("makecpool_pool: expected exactly one .pool file in {}, got {}".format(
            ctx.attr.pool.label,
            [f.basename for f in ctx.files.pool],
        ))
    pool_file = pool_files[0]
    out = ctx.actions.declare_file(ctx.attr.program + "-pool.c")

    # makecpool reads `<program>.pool` from its CWD and writes the C source
    # to stdout. We chdir into the .pool file's directory so the lookup
    # succeeds without us having to copy/symlink the input.
    args = _wrapper_args(ctx, chdir = pool_file.dirname, env = _texlive_env())
    args.add("--stdout", out)
    args.add("--")
    args.add(ctx.executable._makecpool)
    args.add(ctx.attr.program)

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [args],
        inputs = [pool_file],
        outputs = [out],
        tools = [ctx.executable._makecpool],
        mnemonic = "MakeCPool",
        progress_message = "Generating %{output} from string pool",
    )
    return [DefaultInfo(files = depset([out]))]

makecpool_pool = rule(
    doc = """\
Runs `makecpool` on a `.pool` file (from tangle) to emit a C source file
that initializes the engine's string pool at startup.
""",
    implementation = _makecpool_pool_impl,
    attrs = {
        "pool": attr.label(
            doc = "Target producing the .pool file (e.g. a `tangle_web` " +
                  "target whose `emit_pool=True`). The rule selects the " +
                  "single `.pool` file from its outputs.",
            allow_files = [".pool", ".p"],
            mandatory = True,
        ),
        "program": attr.string(
            doc = "Program name (used to name the output and inside the C).",
            mandatory = True,
        ),
        "_makecpool": attr.label(
            default = Label("//texk/web2c/web2c:makecpool"),
            executable = True,
            cfg = "exec",
        ),
        "_process_wrapper": attr.label(
            default = Label("//bazel:process_wrapper"),
            executable = True,
            cfg = "exec",
        ),
    },
)

# =============================================================================
# tex_engine macro (composes tangle_web + web2c_convert + cc_binary)
# =============================================================================

def tex_engine(
        name,
        web = None,
        ch = None,
        extra_c_srcs = [],
        extra_hdrs = [],
        deps = [],
        copts = [],
        local_defines = [],
        linkopts = [],
        visibility = ["//visibility:public"]):
    """Full pipeline for a WEB-based TeX engine.

    Args:
        name: Engine name (e.g., "tex", "pdftex").
        web: Label of the .web source file. If None, assumes C-only engine.
        ch: Label of the .ch change file.
        extra_c_srcs: Additional C source files/labels.
        extra_hdrs: Additional header files/labels.
        deps: Additional cc_library dependencies.
        copts: Additional compiler flags.
        local_defines: Additional preprocessor defines.
        linkopts: Additional linker flags.
        visibility: Bazel visibility.
    """
    all_srcs = list(extra_c_srcs)
    all_hdrs = list(extra_hdrs)

    if web:
        tangle_web(
            name = name + "_p",
            web = web,
            ch = ch,
        )
        web2c_convert(
            name = name + "_c",
            src = ":" + name + "_p",
            program = name,
            outs = [
                name + "0.c",
                name + "1.c",
                name + "2.c",
                name + "ini.c",
                name + "d.h",
                name + "coerce.h",
            ],
        )
        all_srcs.extend([
            ":" + name + "_c",
        ])

    cc_binary(
        name = name,
        srcs = all_srcs + all_hdrs,
        copts = TEXLIVE_COPTS + copts,
        local_defines = TEXLIVE_LOCAL_DEFINES + local_defines,
        linkopts = MATH_LINKOPTS + linkopts,
        deps = [
            Label("//texk/kpathsea"),
            Label("//texk/web2c:web2c_lib"),
            Label("@zlib"),
        ] + deps,
        visibility = visibility,
    )

# =============================================================================
# web_utility macro (simple WEB → C → binary pipeline)
# =============================================================================

def web_utility(name, web = None, ch = None, extra_srcs = None, tags = None, deps = None):
    """Build a plain WEB helper program (dvitype, tftopl, weave, ...).

    Unlike `tex_engine`, these don't need splitup/pool/coerce.h/textual
    lib/texmfmp.c inclusion — just tangle → web2c → compile. Every entry
    in texk/web2c/am/web.am for `nodist_<name>_SOURCES = <name>.c <name>.h`
    fits this shape.

    Args:
        name: Program name (e.g., "dvitype"). Also the base filename of
            the .web / .ch inputs.
        web: Label of the .web file. Defaults to `<name>.web`.
        ch: Label of the .ch change file. Defaults to `<name>.ch`.
        extra_srcs: Additional source files (labels or filenames) — e.g.
            gftodvi's `dist_gftodvi_SOURCES = gftodmem.h`.
        tags: Bazel tags. Defaults to `["manual"]` — the WEB helpers are
            not in the default consumer surface.
        deps: Additional cc_binary dependencies beyond kpathsea + web2c_lib.
    """
    web = web or (name + ".web")
    ch = ch or (name + ".ch")
    tags = tags if tags != None else _MANUAL_TAGS
    deps = deps or []
    extra_srcs = extra_srcs or []

    tangle_web(
        name = name + "_p",
        web = web,
        ch = ch,
        program = name,
        tags = tags,
    )
    web2c_convert(
        name = name + "_c_gen",
        src = ":" + name + "_p",
        program = name,
        outs = [name + ".c", name + ".h"],
        defines = [_WEB2C_COMMON_DEFINES],
        tags = tags,
    )
    cc_binary(
        name = name,
        srcs = [":" + name + "_c_gen"] + extra_srcs,
        copts = TEXLIVE_COPTS,
        local_defines = TEXLIVE_LOCAL_DEFINES,
        tags = tags,
        visibility = ["//visibility:public"],
        deps = [_KPATHSEA_LABEL, _WEB2C_LIB_LABEL] + deps,
    )

# =============================================================================
# texk_program macro
# =============================================================================

def texk_program(
        name,
        srcs = [],
        hdrs = [],
        deps = [],
        copts = [],
        local_defines = [],
        linkopts = [],
        tags = [],
        target_compatible_with = [],
        visibility = ["//visibility:public"]):
    """Simple texk utility program depending on kpathsea.

    Args:
        name: Program name.
        srcs: Source files. Callers must pass an explicit list (often a glob).
        hdrs: Header files. Callers must pass an explicit list (often a glob).
        deps: Additional dependencies beyond kpathsea.
        copts: Additional compiler flags.
        local_defines: Additional preprocessor defines.
        linkopts: Additional linker flags.
        tags: Bazel target tags.
        target_compatible_with: Platform constraints; see Bazel docs.
        visibility: Bazel visibility.
    """
    cc_binary(
        name = name,
        srcs = srcs + hdrs,
        # TL_VERSION / TEX_LIVE_VERSION come from a force-included header
        # (//bazel:tl_strings) rather than -D copts because Bazel/cl.exe
        # response-file quoting eats whitespace in string-valued defines.
        copts = TEXLIVE_COPTS + copts +
                force_include_copts("tl_strings.h"),
        # Match upstream texk/*/Makefile.am: every texk utility's
        # AM_CPPFLAGS sets -DKPATHSEA -DUNIX -DTEXLIVE so the kpathsea
        # integration code paths (10+ tools) actually compile in. Without
        # these the binaries link kpathsea but never call it — they fall
        # back to non-TL path-search and silently lose TEXMF awareness.
        # UNIX is suppressed on MSVC (see TEXK_UNIX_DEFINES).
        local_defines = TEXLIVE_LOCAL_DEFINES + TEXK_UNIX_DEFINES + [
            "KPATHSEA",
            "TEXLIVE",
        ] + local_defines,
        linkopts = MATH_LINKOPTS + linkopts,
        tags = tags,
        target_compatible_with = target_compatible_with,
        deps = [
            Label("//bazel:tl_strings"),
            Label("//texk/kpathsea"),
        ] + deps,
        visibility = visibility,
    )

# =============================================================================
# sh_texlive_test macro
# =============================================================================

def sh_texlive_test(
        name,
        main,
        bin,
        srcs = [],
        data = [],
        env = {},
        **kwargs):
    """Run a TeX Live `*.test` shell script with BinDir / ExeExt set up.

    Uses //bazel:texlive_test_wrapper as the entry-point so the test can
    locate companion binaries via the bash runfiles library — independent
    of where Bazel happens to stage them.

    Args:
        name: Test target name.
        main: A label for the `.test` shell script to execute.
        bin: A binary target whose runfiles location determines
            `BinDir` (i.e. the directory the test expects binaries in).
        srcs: Additional shell scripts bundled with the test (sourced by
            `main` or invoked from it).
        data: Additional runfiles needed by the test (other binaries,
            input fixtures, fonts).
        env: Extra environment variables to forward to the test script.
        **kwargs: Forwarded to sh_test (size, timeout, tags, etc.).
    """
    sh_library(
        name = "{}.lib".format(name),
        srcs = [main] + srcs,
        tags = ["manual"],
    )
    sh_test(
        name = name,
        srcs = [Label("//bazel:texlive_test_wrapper")],
        args = [
            "$(rlocationpath {})".format(bin),
            "$(rlocationpath {})".format(main),
        ],
        data = [
            bin,
            main,
        ] + data,
        env_inherit = ["PATH"],
        deps = [
            ":{}.lib".format(name),
            Label("@rules_shell//shell/runfiles"),
        ],
        env = env,
        **kwargs
    )

# =============================================================================
# texlive_format rule
# =============================================================================

def _texlive_format_impl(ctx):
    fmt = ctx.actions.declare_file(ctx.attr.format_name + ".fmt")
    log = ctx.actions.declare_file(ctx.attr.format_name + ".log")
    outputs = [fmt, log]

    # TEXMFCNF: dir holding texmf.cnf; TEXMF: dir treated as the
    # texmf root (so $TEXMF/tex/latex/... lookups resolve). Derive both
    # from a single marker file passed in via `texmf_cnf`, which we use
    # as the canonical anchor into the staged texmf-dist tree.
    texmf_cnf = ctx.file.texmf_cnf
    texmfcnf_dir = texmf_cnf.dirname  # e.g. <root>/web2c/
    texmf_root = texmfcnf_dir.rsplit("/web2c", 1)[0]
    args = _wrapper_args(
        ctx,
        env = _texlive_env({
            "TEXMF": texmf_root,
            "TEXMFCNF": texmfcnf_dir,
            "TEXMFROOT": texmf_root,
        }),
        quiet = True,
    )
    args.add("--")
    args.add(ctx.executable.engine)
    args.add("-ini")
    if ctx.attr.etex:
        args.add("-etex")
    args.add("-output-directory=" + fmt.dirname)
    args.add("-jobname=" + ctx.attr.format_name)
    args.add(ctx.attr.ini_command)

    ctx.actions.run(
        executable = ctx.executable._process_wrapper,
        arguments = [args],
        inputs = ctx.files.data + [texmf_cnf],
        outputs = outputs,
        tools = [ctx.executable.engine],
        mnemonic = "TexliveFormat",
        progress_message = "Compiling " + ctx.attr.format_name + ".fmt with " +
                           ctx.executable.engine.basename,
    )
    return [DefaultInfo(files = depset([fmt]))]

texlive_format = rule(
    doc = """\
Compile a TeX format file (e.g. `pdflatex.fmt`) by running an engine in
ini mode against a `.ini` source from the texmf-dist tree.

Equivalent to the upstream `fmtutil` step: `engine -ini -etex *latex.ini`.
The engine, ini-command, and supporting texmf data are all parameters so
the same rule serves pdftex/xetex/luatex/etc.
""",
    implementation = _texlive_format_impl,
    attrs = {
        "data": attr.label_list(
            doc = "Texmf data needed by the engine to resolve every input.",
            allow_files = True,
        ),
        "engine": attr.label(
            doc = "TeX engine binary (e.g. //texk/web2c:pdftex).",
            executable = True,
            mandatory = True,
            cfg = "exec",
        ),
        "etex": attr.bool(
            doc = "Pass `-etex` to the engine (required for *latex formats).",
            default = True,
        ),
        "format_name": attr.string(
            doc = "Output stem (`pdflatex` produces `pdflatex.fmt`).",
            mandatory = True,
        ),
        "ini_command": attr.string(
            doc = "The TeX command run after engine startup; usually " +
                  "`*<inifile>.ini` so the engine reads the .ini directly.",
            mandatory = True,
        ),
        "texmf_cnf": attr.label(
            doc = "The `texmf.cnf` file under `web2c/`. Used as the " +
                  "anchor to derive both `TEXMFCNF` (its directory) and " +
                  "`TEXMF` (the parent of `web2c/`).",
            allow_single_file = True,
            mandatory = True,
        ),
        "_process_wrapper": attr.label(
            default = Label("//bazel:process_wrapper"),
            executable = True,
            cfg = "exec",
        ),
    },
)
