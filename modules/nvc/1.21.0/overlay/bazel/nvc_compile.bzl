"""Starlark rule for compiling VHDL libraries with `nvc -a`.

Source declarations come from the standard `@rules_vhdl//vhdl:defs.bzl#vhdl_library`
rule, which only collects sources and metadata (library name, VHDL
standard, transitive dep graph). This module supplies the matching
backend: `nvc_compile` consumes a `VhdlInfo` provider and produces a
TreeArtifact of the compiled library, ready to be loaded by the nvc
simulator at runtime.

The split mirrors what `rules_ghdl` does for GHDL — a third-party
ruleset that owns the source layer, and a backend-specific rule that
runs the simulator's analyser.

Cyclic interleaving between sibling libraries (`lib/std/textio-body.vhd`
`use nvc.polyfill.all;` forces it to be compiled AFTER lib/nvc/NVC.POLYFILL,
even though every NVC.* unit transitively needs STD.STANDARD) is handled
through the `seed` attribute: an optional sibling `nvc_compile` target
whose contents are copied into the work directory before compilation
begins. That lets the upstream multi-phase bootstrap collapse into a
small number of Bazel targets per standard.

The actual `nvc -a` invocations run through `bazel/vhdl_compile.cc`,
called via `ctx.actions.run` with a named-argument CLI. The rule
itself just assembles the arguments — no inline shell command, no
`run_shell`.
"""

load("@rules_vhdl//vhdl:defs.bzl", "VhdlInfo", "vhdl_library")

NvcLibraryInfo = provider(
    doc = "Compiled NVC VHDL library output directory.",
    fields = {
        "lib_dir": "TreeArtifact containing the compiled library.",
        "transitive_lib_dirs": "depset[File]: every nvc_compile dir that must be in -L when consumers analyse against this library.",
    },
)

def _nvc_compile_impl(ctx):
    nvc = ctx.executable.nvc
    vhdl_info = ctx.attr.lib[VhdlInfo]

    # `library` (from VhdlInfo) is the NVC library identifier. NVC
    # derives it from the on-disk directory basename (everything before
    # the first `.`), with the `.08`/`.19` suffix encoding the
    # required VHDL standard. Each compile lives at
    # `vhdl_libs/<target_name>/<library>/`:
    # - the <target_name> layer guarantees Bazel-output-path uniqueness
    #   when two targets share the same NVC library name (the
    #   bootstrap "split" pattern),
    # - the <library> dir is what NVC reads as the library identifier,
    # - the parent (`vhdl_libs/<target_name>/`) is exactly what `-L`
    #   consumers need.
    library = vhdl_info.library
    lib_dir = ctx.actions.declare_directory("vhdl_libs/{}/{}".format(ctx.label.name, library))

    standard = ctx.attr.standard or vhdl_info.standard
    if not standard:
        fail("nvc_compile {}: VHDL standard must be set on the lib or via the `standard` attr".format(ctx.label))

    # Collect dep dirs from sibling nvc_compile targets; their tree
    # artifacts must reach the action as inputs, and their parent dirs
    # become -L paths.
    direct_dep_dirs = [dep[NvcLibraryInfo].lib_dir for dep in ctx.attr.deps]
    transitive_dep_dirs = depset(
        direct = direct_dep_dirs,
        transitive = [dep[NvcLibraryInfo].transitive_lib_dirs for dep in ctx.attr.deps],
    )
    all_dep_dirs = transitive_dep_dirs.to_list()

    args = ctx.actions.args()
    args.add("--nvc", nvc)
    args.add("--std", standard)
    args.add_all([lib_dir], before_each = "--work", expand_directories = False)

    seed_inputs = []
    if ctx.attr.seed:
        seed_dir = ctx.attr.seed[NvcLibraryInfo].lib_dir
        seed_inputs.append(seed_dir)
        args.add_all([seed_dir], before_each = "--seed-from", expand_directories = False)

    if ctx.attr.bootstrap:
        args.add("--bootstrap-first")
    if ctx.attr.relaxed:
        args.add("--relaxed")

    # `-L` accepts the directory CONTAINING the library dir. Pass one
    # entry per unique transitive dep dir; the wrapper script also
    # prepends the work-dir's own parent, so STD (and the in-progress
    # library itself) stay reachable across the multi-call sequence.
    seen_parents = {}
    for d in all_dep_dirs:
        seen_parents[d.dirname] = True
    args.add_all(sorted(seen_parents.keys()), before_each = "-L")

    srcs = vhdl_info.srcs.to_list()
    args.add_all(srcs, before_each = "--src")

    ctx.actions.run(
        executable = ctx.executable._tool,
        arguments = [args],
        inputs = depset(direct = srcs + seed_inputs, transitive = [transitive_dep_dirs]),
        tools = [nvc],
        outputs = [lib_dir],
        mnemonic = "NvcAnalyse",
        progress_message = "Analysing VHDL library {} ({})".format(library, standard),
    )

    return [
        DefaultInfo(files = depset([lib_dir])),
        NvcLibraryInfo(
            lib_dir = lib_dir,
            transitive_lib_dirs = depset(direct = direct_dep_dirs, transitive = [transitive_dep_dirs]),
        ),
    ]

nvc_compile = rule(
    implementation = _nvc_compile_impl,
    doc = """Compile a `@rules_vhdl//vhdl:vhdl_library` target with `nvc -a`.

Output is a TreeArtifact containing the compiled `.NVC` units, with
the directory basename matching the VHDL `library` name so the nvc
runtime can locate it via `-L`.
""",
    attrs = {
        "bootstrap": attr.bool(
            doc = "Pass --bootstrap to the first analysis (required for STD.STANDARD).",
            default = False,
        ),
        "deps": attr.label_list(
            doc = "Other nvc_compile targets whose units may be referenced.",
            providers = [NvcLibraryInfo],
        ),
        "lib": attr.label(
            doc = "A @rules_vhdl//vhdl:vhdl_library target carrying the sources, library name, VHDL standard, and dep graph.",
            mandatory = True,
            providers = [VhdlInfo],
        ),
        "nvc": attr.label(
            doc = "The nvc binary to use for compilation.",
            executable = True,
            cfg = "exec",
            default = Label("//:nvc"),
        ),
        "relaxed": attr.bool(
            doc = "Pass --relaxed to nvc (loosen 1993 LRM checks; used by VITAL primitives).",
            default = False,
        ),
        "seed": attr.label(
            doc = "Optional sibling nvc_compile whose compiled contents are copied into the work dir before this library's srcs are analysed. Lets a split library (e.g. std_base → std_full) extend an earlier build without re-running its analyses.",
            providers = [NvcLibraryInfo],
        ),
        "standard": attr.string(
            doc = "Override the VHDL standard from the `lib` (rules_vhdl) target. Useful when the same source files are reused across standards.",
            default = "",
            values = ["", "1993", "2000", "2002", "2008", "2019"],
        ),
        "_tool": attr.label(
            default = Label("//bazel:vhdl_compile"),
            executable = True,
            cfg = "exec",
        ),
    },
    provides = [NvcLibraryInfo],
)

def vhdl_chain(
        *,
        name,
        library,
        standard,
        phases,
        bootstrap = False,
        relaxed = False,
        deps = None,
        seed = None,
        visibility = None):
    """Emit an ordered chain of `vhdl_library` + `nvc_compile` targets.

    The bootstrap of NVC's shipped VHDL libraries (STD, IEEE, NVC,
    SYNOPSYS, VITAL) is sensitive to source-file ordering: bodies must
    follow declarations, IEEE.NUMERIC_STD uses IEEE.STD_LOGIC_1164, and
    some bodies reference NVC.POLYFILL which is itself built later.

    Buildifier will sort the `srcs` list of any single `vhdl_library`
    call, so encoding the order as a flat list is unreliable. Instead,
    `vhdl_chain` accepts a list of `(suffix, [srcs])` tuples — buildifier
    leaves the tuple order intact — and emits one `vhdl_library` and one
    `nvc_compile` per phase. Each compile is `seed=`-ed off the previous
    phase, so units analysed earlier in the chain are visible to later
    ones without redoing the work.

    The final phase's compile is named `<name>` (the public handle that
    other targets depend on); intermediate compiles are named
    `<name>__<suffix>` to keep their internal status visible.

    Args:
      name: Final compile target name (e.g. `"std"`, `"ieee_decls"`).
      library: VHDL library identifier (passed verbatim to vhdl_library).
      standard: VHDL standard (`"1993"`, `"2008"`, or `"2019"`).
      phases: Ordered list of `(suffix, srcs)` tuples. `srcs` is a list
        of source files; `suffix` is appended to `name` for intermediate
        compiles. The LAST entry's compile is named `name` directly.
      bootstrap: If True, the first phase passes `--bootstrap` to nvc.
      relaxed: If True, every phase passes `--relaxed` to nvc.
      deps: Other `nvc_compile` targets visible from every phase (e.g.
        `:std_base`). Defaults to an empty list.
      seed: Optional sibling `nvc_compile` (label string) whose compiled
        contents are copied into the first phase's work dir, so the
        chain extends an existing library rather than starting from
        scratch. Used to chain `:std` (TEXTIO-body) on top of
        `:std_base`, etc.
      visibility: Visibility of the final compile target only.

    Returns:
      The Bazel target name of the final compile (always `name`).
    """
    if not phases:
        fail("vhdl_chain '{}' must have at least one phase".format(name))

    base_deps = deps or []

    # prev_seed tracks the previous phase's compile target as a label
    # string suitable for direct use in `nvc_compile(seed = ...)`. The
    # initial value comes from the user-supplied `seed` arg, so a
    # chain of length 1 can still extend an existing compile (e.g. the
    # `:std` chain that adds STD.TEXTIO-body on top of `:std_base`).
    prev_seed = seed
    final_target = None
    for i, (suffix, srcs) in enumerate(phases):
        is_last = (i == len(phases) - 1)
        compile_name = name if is_last else "{}__{}".format(name, suffix)
        lib_name = "_{}__{}_lib".format(name, suffix)

        vhdl_library(
            name = lib_name,
            srcs = srcs,
            library = library,
            standard = standard,
            visibility = ["//visibility:private"],
        )

        nvc_compile(
            name = compile_name,
            bootstrap = bootstrap and i == 0,
            deps = base_deps,
            lib = ":" + lib_name,
            relaxed = relaxed,
            seed = prev_seed,
            visibility = visibility if is_last else ["//visibility:private"],
        )

        prev_seed = ":" + compile_name
        final_target = compile_name

    return final_target
