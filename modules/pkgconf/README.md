# pkgconf

Ported from upstream's `meson.build` with
[`rules_cc_autoconf`](https://registry.bazel.build/modules/rules_cc_autoconf).
`overlay/BUILD.bazel` documents the port; below is only what a version bump needs.

## Upgrading

Template entries in `config.h` follow the tarball, but the checks that fill them
in are written by hand. An entry with no check renders as `#undef`, and pkgconf
tests these with `#if`, not `#ifdef`, so it silently falls back to `bsdstubs.c`.
3.0.5 added three entries and dropped seven — verify rather than assume:

```shell
bazel build @pkgconf//:config_h
grep '#undef' bazel-bin/external/pkgconf+/libpkgconf/config.h
```

`_LARGE_FILES` is AIX-only and the only `#undef` a correct build emits; a failed
probe renders as `#define HAVE_DECL_X 0`.

Then re-point the `pkgconf-3.0.7` GitHub links in `overlay/` — a fifth of the
line anchors moved across one patch release — run
`bazel run //tools:update_integrity -- pkgconf --version=<new>`, and test both
runfiles modes: `--noenable_runfiles` is the only local way to hit the path
Windows always takes.

Upstream removes autotools in 3.1 and the 2.x → 3.0 bump restructured the tests
wholesale, so expect a minor bump to be a rewrite.
