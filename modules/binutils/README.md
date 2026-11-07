# binutils

This module uses [`rules_cc_autoconf`](https://registry.bazel.build/modules/rules_cc_autoconf)
to detect platform-specific configuration at build time rather than relying on hard-coded defaults.

There is no `--target` flag: every program is built for the Bazel target
platform, and each `cc_*` target picks its sources and defines with a
`select()` on the `@platforms` os/cpu pair (`overlay/platforms.bzl`).
`overlay/targets.bzl` lists the supported pairs; the data behind the selects
-- which BFD vectors, disassemblers, assembler back end, linker emulations
and auxiliary programs upstream configures for each platform -- lives in
the `targets.bzl` of the package that consumes it (`bfd/`, `opcodes/`,
`gas/`, `ld/`, `binutils/`).  `generate_targets.py` derives all of them by
running the shell tables of the release tarball (`bfd/config.bfd`,
`gas/configure.tgt`, `ld/configure.tgt`, `binutils/configure.tgt`, the
`emulparams` files, the top-level `configure.ac`) once per supported
platform, and also writes `overlay/bfd/targmatch.h`:

```
python3 modules/binutils/generate_targets.py /path/to/binutils-2.47
```

Regenerate them when updating to a new release or adding a platform to its
`PLATFORMS` table.  The `.bzl` files are load-visible to this module only;
the public interface is the programs, the libraries and the flags.  The table covers the operating systems binutils has host
support for (Linux, Android, NixOS, ChromiumOS, Windows via mingw-w64,
macOS, FreeBSD, NetBSD, OpenBSD, Haiku, VxWorks, QNX, Fuchsia) on the cpus
they run on.  A platform that is not in the table, or a program upstream
does not build for it (`as`, `ld` and `gprof` on Darwin; `ld` on some BSD
arm ports; `dlltool`, `windres`, `windmc` and `dllwrap` off Windows), fails
at analysis with the ordinary no-matching-`select()` error.

An os/cpu pair says less than a triple, so where several triples share a
pair the entry assumes the common one: Linux is `-gnu` rather than musl,
`armv7` is hard-float, `mips64` is big-endian n64, `ppc` is 64-bit
big-endian, Windows is mingw-w64.  TODO: split the Linux entries by libc on
the `glibc`/`musl` constraints of
[platforms_contrib](https://github.com/bazel-contrib/platforms_contrib/)
once a release of that module carries them.  The full list of assumptions
is next to the `PLATFORMS` table in `generate_targets.py`.

`ld` is the one place a shell is still needed: its emulation sources and
default linker scripts come from upstream's `genscripts.sh`, which runs the
`emultempl`/`scripttempl` templates (some 20k lines of shell) per emulation.
