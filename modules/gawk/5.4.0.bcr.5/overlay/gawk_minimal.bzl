"""`gawk_minimal` - a `gawk` binary that's guaranteed to pull no optional deps.

A transition forces every optional `bool_flag` (`//:mpfr`) off before the
inner `:gawk` is analyzed, so downstream consumers can depend on
`@gawk//:gawk_minimal` without worrying about the calling configuration
turning on MPFR. The motivating case: a module that gawk transitively depends on
at build time — e.g. `ncurses` consuming gawk to generate its `term.h` —
must not be able to drag MPFR back into the dep graph.

Use this when you need gawk during another module's build (genrule tools,
extension generators, ...). For everyday `gawk` invocations from a leaf
binary, `@gawk//:gawk` is what you want.
"""

_OPTIONAL_BOOL_FLAGS = [
    Label("//:mpfr"),
]

_OPTIONAL_LABEL_FLAGS = {}

def _minimal_transition_impl(_settings, _attr):
    out = {str(flag): False for flag in _OPTIONAL_BOOL_FLAGS}
    for flag, default in _OPTIONAL_LABEL_FLAGS.items():
        out[str(flag)] = default
    return out

_minimal_transition = transition(
    implementation = _minimal_transition_impl,
    inputs = [],
    outputs = [str(flag) for flag in _OPTIONAL_BOOL_FLAGS] +
              [str(flag) for flag in _OPTIONAL_LABEL_FLAGS],
)

def _gawk_minimal_impl(ctx):
    # `cfg = _minimal_transition` makes `ctx.attr.target` a single-element
    # list (one transitioned configuration).
    inner = ctx.attr.target[0]
    inner_executable = inner[DefaultInfo].files_to_run.executable

    # Symlink the inner binary under this rule's own name so `bazel run`
    # finds an executable at the predictable label path. Preserve the
    # inner's extension (`.exe` on Windows) — without it the symlink
    # wouldn't actually be invokable by the OS loader.
    ext = inner_executable.extension
    out_name = ctx.label.name + (("." + ext) if ext else "")
    out = ctx.actions.declare_file(out_name)
    ctx.actions.symlink(
        output = out,
        target_file = inner_executable,
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = [inner_executable])
    runfiles = runfiles.merge(inner[DefaultInfo].default_runfiles)

    return [DefaultInfo(executable = out, runfiles = runfiles)]

gawk_minimal = rule(
    implementation = _gawk_minimal_impl,
    doc = """A `gawk` binary built with every optional dependency forced off.

Wraps `//:gawk` in an incoming-edge transition that pins `//:mpfr` to
`False`. This lets downstream modules depend on gawk during their build
without the risk that a user's `--//:mpfr=true` drags MPFR (and GMP) into a
configuration that can't build them.
""",
    attrs = {
        "target": attr.label(
            doc = """\
The gawk binary to wrap. Defaults to `//:gawk`; override only when
substituting a custom build of gawk that should still get the
optional-flags-off treatment.
""",
            cfg = _minimal_transition,
            default = Label("//:gawk"),
            executable = True,
        ),
    },
    executable = True,
)
