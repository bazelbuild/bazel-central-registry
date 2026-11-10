# Bazel build of jemalloc

The [Bazel](https://bazel.build/) build of [jemalloc](https://github.com/jemalloc/jemalloc), published to the
[Bazel Central Registry](https://registry.bazel.build/modules/jemalloc) as the `jemalloc` module, is maintained at
https://github.com/sallustfire/jemalloc. Each `bcr-<version>` branch there is upstream's source for that jemalloc
release plus the Bazel build. Report problems with the Bazel build and send changes to it there; problems in jemalloc
itself belong upstream.

The upstream jemalloc build performs a number of feature detection steps in the configure script. Here the checks
that ask the toolchain (functions and their signatures, MADV_* constants, builtins, attributes, atomics, type sizes and
byte order) are copies of configure.ac's test programs, compiled or linked by rules_cc_autoconf with the target's
toolchain. configure's host table is expressed as platform selects and transition defaults. What configure learns by
running a program on the build machine (page size, virtual address bits, huge page size) is set by flags under
//settings/platform; lg_page and lg_vaddr have per-platform defaults.

## Usage

See the [examples/host_toolchain/BUILD.bazel](examples/host_toolchain/BUILD.bazel) file for examples of how to consume
`@jemalloc`.

## Notes

- **//settings/flags:jemalloc_prefix (--with-jemalloc-prefix):** As in the make build, this defaults to "je_" on macOS
 and Windows and to no prefix elsewhere. On macOS jemalloc replaces malloc by overlaying the default malloc zone rather
 than by exporting malloc, free and so on; see //settings/flags:enable_zone_allocator below. A prefix renames the
 public API, malloc_conf, /etc/malloc.conf and MALLOC_CONF as INSTALL.md's --with-jemalloc-prefix describes. To call
 the API by its je_* names (je_mallctl, je_mallocx, ...) under any prefix, define JEMALLOC_NO_DEMANGLE before including
 jemalloc/jemalloc.h. Set the flag, or jemalloc()'s jemalloc_prefix, to choose a prefix explicitly. The flag defaults
 to "__auto__", which only jemalloc's own transition resolves, so a select() on the flag outside it sees "__auto__",
 and the flag provides no $(JEMALLOC_PREFIX). Set the prefix explicitly where a consumer needs to know it.
- **//settings/flags:enable_zone_allocator (--disable-zone-allocator):** As in the make build, this is on for Darwin
 and off elsewhere, and turning it on for any other platform fails the build. With it on, jemalloc registers a malloc
 zone from a constructor in src/zone.c, so plain malloc reaches jemalloc in every binary that links @jemalloc,
 statically or not; this includes binaries that call jemalloc only through a prefixed API. Turn it off to keep jemalloc
 private to that API. Unlike the make build's static libjemalloc.a, this build links src/zone.c whole (alwayslink), but
 only in links Bazel performs: an archive exported to another build system would need -force_load. An application that
 defines its own global operator new and delete must define every overload it calls, or jemalloc's are linked as well
 and the duplicates fail the link.
- **Library targets:** @jemalloc//:jemalloc is the target to depend on, through deps or the malloc attribute; it
 provides CcInfo and builds no file of its own. Inside, the archives are lib/libjemalloc_core.a and, with the zone
 allocator, lib/libjemalloc_zone.lo; their names are not part of the interface.
- **//settings/flags:nm (NM):** The nm that lists the library's symbols for private_namespace.h, as configure's NM
 does. Unset, it is the C++ toolchain's nm (CcToolchainInfo.nm_executable). rules_cc's rule-based toolchains supply
 that only through a cc_legacy_tool, so with one that declares none, such as the hermetic LLVM toolchain (the `llvm`
 module), the build fails at that step until this is set to an nm target, for example
 `--@jemalloc//settings/flags:nm=@llvm//tools:llvm-nm`, as [examples/hermetic_llvm](examples/hermetic_llvm) does.
- **//settings/platform:lg_vaddr (--with-lg-vaddr):** Defaults as configure does: 48 on aarch64, 57 on x86_64 (the
 configure script's cross compilation value; a native configure runs CPUID instead, which gives 48 on a CPU without
 5-level paging), and the pointer width on any other CPU whose width @platforms makes clear. Any other CPU, such as
 ppc, must set it, or the build fails. Set it explicitly to override. The flag defaults to "__auto__", which only
 jemalloc's own transition resolves, so a select() on the flag or $(LG_VADDR) outside it sees "__auto__". Any value is
 written into the header as is, without checking that it is a number.
- **//settings/platform:lg_page (--with-lg-page):** Defaults to 16 (64 KiB) on aarch64 Linux and Android and on ppc64le
 Linux, so one build runs on kernels with 4K, 16K or 64K pages, at the cost of a coarser page granularity on 4K
 kernels (configure's cross compilation value is 12, which fails at startup on a 16K or 64K kernel). Darwin defaults
 to 14 and everything else to 12. Set it explicitly to override.
- **//settings/platform:lg_hugepage (--with-lg-hugepage):** Defaults to 21 (2 MiB), configure's value when it cannot
 read the huge page size. It must be at least lg_page, as configure requires, or the build fails; so on aarch64 Linux
 and Android and ppc64le Linux, where lg_page defaults to 16, a value below 16 needs lg_page set explicitly too.
- **glibc:** Without a prefix, the __libc_* functions and __posix_memalign are probed and listed (exempt from private
 renaming) wherever they link, and on Linux the hooks __malloc_hook, __realloc_hook, __free_hook and __memalign_hook
 where they still link (glibc before 2.34), exactly as configure does. jemalloc defines the hooks, and aliases the
 __libc_* functions and __posix_memalign, only where the malloc hooks link on glibc; elsewhere, as with configure,
 these names are listed but not defined.

Platform configurations that have defaults that are applied via transition.
- //settings/flags:enable_lazy_lock
- //settings/flags:enable_zone_allocator
- //settings/flags:jemalloc_prefix
- //settings/platform:lg_page
- //settings/platform:lg_vaddr

The optional public functions (memalign, valloc, malloc_size) are exported exactly where configure would export them:
where the target's toolchain links them, as the configured headers record.

## Fidelity with upstream

The upstream build generates several headers with shell, awk and sed scripts, run by configure and make on the host.
Here Bazel generates them with small C++ tools, so a module that depends on `@jemalloc` needs only its C and C++
toolchain: no host shell, awk or sed. As in configure, the public symbols include optional functions only where the
configured headers define the matching macro, so the headers built from them are written when the build runs.
private_namespace.h comes from running the toolchain's `nm`, which the tool can only do on POSIX hosts for now (see
Windows under Known Issues).

The upstream scripts are kept, not replaced. Each generated header has a `fidelity_test` in
[tools/fidelity](tools/fidelity) that runs the unmodified upstream script, as configure.ac invokes it, on the
same inputs and with the same settings, and fails if the outputs differ. The scripts run with hermetic gawk, grep, sed
and coreutils, which are dev dependencies: they are fetched for this repository's tests and never for consumers. The
`upstream-oracle` CI job goes further, building the upstream release with configure and make and comparing every
script-generated header, and the public and wrapped symbol lists, with the Bazel build's.

When upgrading jemalloc, a failing fidelity test means an upstream script changed and its Bazel counterpart must
follow.

## Validated Platforms

Tested in CI with the latest Bazel 7.x, 8.x and 9.x:

- Ubuntu 22.04, 24.04 & 26.04 (x86_64)
- Ubuntu 24.04 (aarch64)
- MacOS 15 & 26 (arm64)

The minimum supported Bazel, 7.4.0, is tested on Ubuntu 24.04 (x86_64) and, for the host toolchain examples only,
MacOS 15.
Profiling (`--config=prof-*`) is tested on Linux only.

## Known Issues

- **Windows:** Upstream's MSVC configuration is translated but has never been built or tested, and will likely fail.
  Generating private_namespace.h fails there regardless: the tool that runs `nm` is not implemented on Windows.
- **FreeBSD:** configure's FreeBSD settings are translated (lazy lock, the vm.overcommit sysctl, -D_BSD_SOURCE for
  probes), but nothing has been built on FreeBSD.

## How the registry entry is produced

The registry entry does not fetch the repository above. It fetches upstream's release tarball (for 5.3.0,
`jemalloc-5.3.0.tar.bz2` from jemalloc's GitHub releases) and adds the Bazel build to it:

- **overlay/** holds every committed file the tarball lacks: the BUILD and .bzl files, MODULE.bazel, settings/, tools/,
  examples/ and this README. The repository's own tooling, listed in `.bcr/fork_only.txt`, stays out.
- **patches/** holds one patch for each upstream file the repository edits, the difference between the committed file
  and the tarball's.

`.github/scripts/export_bcr_entry.py` writes the entry into a registry checkout from a committed ref. It writes
nothing unless the tarball, overlay and patches, applied as Bazel applies them, rebuild that ref byte for byte.
`.bcr/presubmit.yml` becomes the entry's presubmit.

## Contributing

Send changes as pull requests to https://github.com/sallustfire/jemalloc, against the branch for the jemalloc version,
such as `bcr-5.3.0`. Support for a new jemalloc release starts as a new `bcr-<version>` branch.

- Leave upstream's files as upstream ships them where you can. Each edit to one ships to the registry as a patch, so
  edit one only when the Bazel build needs it, and say why in a comment beside the edit.
- A new file ships in the overlay with no further step. List it in `.bcr/fork_only.txt` only if it is tooling for this
  repository, such as CI configuration.
- Run `bazel test //...` at the root and in `examples/host_toolchain` and `examples/hermetic_llvm`. CI runs them on the
  platforms above and builds the upstream release with configure and make to compare.

A release sets `version` in MODULE.bazel to `<upstream>.bcr.<N>`, runs
`.github/scripts/export_bcr_entry.py --registry <registry checkout>`, and opens a pull request against the
[Bazel Central Registry](https://github.com/bazelbuild/bazel-central-registry) with the entry it writes.
