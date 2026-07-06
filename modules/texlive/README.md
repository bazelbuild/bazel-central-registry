# texlive

A Bazel port of [TeX Live](https://tug.org/texlive/) — the upstream-blessed,
cross-platform distribution of TeX, LaTeX, and related programs.

Build files are **hand-crafted** to mirror what upstream's autotools
build (`texk/*/configure.ac` + `texk/*/Makefile.am`) produces, using
[`rules_cc_autoconf`][rca] for the feature-probing `./configure`
would otherwise do.

Runtime data (`texmf-dist`: LaTeX macros, fonts, hyphenation
patterns, configuration) lives in a separate
[`texlive-texmf`](../texlive-texmf) module and gets pulled in
transitively at the matching version.

[rca]: https://github.com/periareon/rules_cc_autoconf

## Adding a new version

The Bazel overlay shadows the upstream `texlive-source/` tree:
binaries and libraries stay at the same paths they live at upstream,
each with a hand-written `BUILD.bazel` next to its sources. The
`bazel/` directory is the only purely Bazel-side addition — it holds
helpers, rules, and tools that have no upstream equivalent.

When bringing up a new release, the usual flow is:

1. Diff the new upstream `texk/*/Makefile.am` / `configure.ac`
   files against the previous release and adjust the corresponding
   `BUILD.bazel`s where source lists, defines, or probes changed.
2. Per-package autoconf probes (`HAVE_CTYPE_H`, `HAVE_FSEEKO`, etc.)
   should come from the root `//:configure` rule via `autoconf_hdr` —
   add new probes there rather than hardcoding defines. Project-policy
   knobs (engine selectors, backend flags) stay as `local_defines`.
3. Patches under `patches/` exist **only** for MSVC compatibility
   where upstream's Windows build cross-compiles with MinGW gcc
   instead. Patches that would change runtime behavior, output, or
   semantics on any platform are out of scope — those belong in the
   BUILD.bazel.
