# Bazel build of jemalloc

The [Bazel](https://bazel.build/) build of [jemalloc](https://github.com/jemalloc/jemalloc), published to the
[Bazel Central Registry](https://registry.bazel.build/modules/jemalloc) as the `jemalloc` module, is maintained at
https://github.com/sallustfire/jemalloc. Each `bcr-<version>` branch there is upstream's source for that jemalloc
release plus the Bazel build. Report problems with the Bazel build and send changes to it there; problems in jemalloc
itself belong upstream.

The upstream jemalloc build performs a number of feature detection steps in the configure script. Here the checks
that ask the toolchain (functions and their signatures, MADV_* constants, builtins, attributes, atomics, type sizes and
byte order) are copies of configure.ac's test programs, compiled or linked by rules_cc_autoconf with the target's
toolchain. configure's host table is expressed as platform selects. What configure learns by running a program on the
build machine (page size, virtual address bits, huge page size) is set by flags under //settings/platform, and lg_page
and lg_vaddr have per-platform defaults. Whether the CPU has rdtscp, which configure also learns by running a program,
is left undefined; see JEMALLOC_HAVE_RDTSCP below. Where configure runs a program to confirm that the running kernel
supports an interface the C library provides, the check only links it for the target and assumes that support; see
JEMALLOC_HAVE_PTHREAD_COND_TIMEDWAIT_MONOTONIC below.

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
 to "__auto__", which jemalloc resolves for the target platform, so a select() on the flag sees "__auto__", and the
 flag provides no $(JEMALLOC_PREFIX). Set the prefix explicitly where a consumer needs to know it.
- **//settings/flags:enable_zone_allocator (--disable-zone-allocator):** As in the make build, this is on for Darwin
 and off elsewhere, and turning it on for any other platform fails the build. With it on, jemalloc registers a malloc
 zone from a constructor in src/zone.c, so plain malloc reaches jemalloc in every binary that links @jemalloc,
 statically or not; this includes binaries that call jemalloc only through a prefixed API. Turn it off to keep jemalloc
 private to that API. Unlike the make build's static libjemalloc.a, the library links with -u
 <private namespace>zone_register on Darwin, which keeps src/zone.c in a static link; an archive exported to another
 build system needs the same option. An application that defines its own global operator new and delete must define
 every overload it calls, or jemalloc's are linked as well and the duplicates fail the link.
- **//settings/flags:enable_debug (--enable-debug):** Turns on jemalloc debug (JEMALLOC_DEBUG). Defaults to
 "__auto__", which follows the compilation mode and defines it in `-c dbg` builds only; "yes" and "no" set it in any
 compilation mode. configure's --enable-debug also turns off its optimization flags; here the compilation mode alone
 decides optimization. jemalloc debug includes the checks of //settings/flags:enable_opt_safety_checks
 (--enable-opt-safety-checks), //settings/flags:enable_opt_size_checks (--enable-opt-size-checks) and
 //settings/flags:enable_uaf_detection (--enable-uaf-detection), which, off by default, turn them on without the rest
 of debug. Set to False, they do not turn off the checks debug includes. jemalloc()'s debug, opt_safety_checks,
 opt_size_checks and uaf_detection set them per target.
- **Library targets:** @jemalloc//:jemalloc is the cc_library to depend on, through deps or the malloc attribute. It
 builds libjemalloc.a and no shared library of its own (linkstatic). Each jemalloc() target is a library of its own,
 built with its attributes' settings.
- **//settings/flags:nm (NM):** The nm that lists the library's symbols for private_namespace.h, as configure's NM
 does. Unset, it is the C++ toolchain's nm (CcToolchainInfo.nm_executable). rules_cc's rule-based toolchains supply
 that only through a cc_legacy_tool, so with one that declares none, such as the hermetic LLVM toolchain (the `llvm`
 module), the build fails at that step until this is set to an nm target, for example
 `--@jemalloc//settings/flags:nm=@llvm//tools:llvm-nm`, as [examples/hermetic_llvm](examples/hermetic_llvm) does.
 MSVC-compatible toolchains declare no nm, so with msvc-cl the symbols are listed by the toolchain's linker as
 `link /DUMP /SYMBOLS`, which is dumpbin, and with clang-cl by the llvm-nm.exe beside its clang-cl.exe.
- **//settings/platform:lg_vaddr (--with-lg-vaddr):** Defaults as configure does: 48 on aarch64, 57 on x86_64 (the
 configure script's cross compilation value; a native configure runs CPUID instead, which gives 48 on a CPU without
 5-level paging), and the pointer width on any other CPU whose width @platforms makes clear. Any other CPU, such as
 ppc, must set it, or the build fails. Set it explicitly to override. The flag defaults to "__auto__", which jemalloc
 resolves for the target platform, so a select() on the flag sees "__auto__". Any value is written into the header as
 is, without checking that it is a number.
- **//settings/platform:lg_page (--with-lg-page):** Defaults to 16 (64 KiB) on aarch64 Linux and Android and on ppc64le
 Linux, so one build runs on kernels with 4K, 16K or 64K pages, at the cost of a coarser page granularity on 4K
 kernels (configure's cross compilation value is 12, which fails at startup on a 16K or 64K kernel). Darwin defaults
 to 14 and everything else to 12. Set it explicitly to override. It must be at least 8 (256-byte pages), as configure
 requires, or the build fails. It is a string flag, written into the header as given; like configure's `test`, the
 checks read it as an integer when it is an optional sign and decimal digits, with or without surrounding spaces or
 tabs, and any other value passes through unchecked.
- **//settings/platform:lg_hugepage (--with-lg-hugepage):** Defaults to 21 (2 MiB), configure's value when it cannot
 read the huge page size. It is an integer flag. It must be greater than lg_page, as configure requires, or the build
 fails; so on aarch64 Linux and Android and ppc64le Linux, where lg_page defaults to 16, a value of 16 or below needs
 lg_page set explicitly too. The comparison is skipped when lg_page does not read as an integer.
- **JEMALLOC_HAVE_RDTSCP (no configure option):** Never defined, with no flag to change it. configure decides it by
 running a program on an x86_64 build machine, so a native configure defines it on nearly every x86_64 CPU and a cross
 build leaves it undefined; which CPU the program ran on says nothing about the target's, and no toolchain check can.
 Nothing reachable reads it: only the POSIX CPU backend does, after sched_getcpu, and that backend supports
 percpu_arena, its only caller, only with sched_getcpu. Should a release read it where it can run, it becomes a
 //settings/platform flag.
- **JEMALLOC_HAVE_PTHREAD_COND_TIMEDWAIT_MONOTONIC (no configure option):** Whether the background thread's condition
 variable waits on CLOCK_MONOTONIC, so a change to the wall clock does not move its deadlines. configure runs a program
 that sets the clock with pthread_condattr_setclock and checks that each call succeeds, which confirms that the running
 kernel accepts CLOCK_MONOTONIC; a cross build gets "no". Here a check links the same program for the target instead,
 which shows only that the C library provides the functions and the constant. That the kernel accepts CLOCK_MONOTONIC is
 an assumption this build makes about the target, true on the kernels glibc, musl, Bionic and FreeBSD's libc support,
 not something the link observes. So where configure, cross building, leaves the macro undefined and this build defines
 it, the difference is intended. Where the target's kernel rejects CLOCK_MONOTONIC for a condition variable, jemalloc
 fails to initialize: background_thread_boot1 initializes the background threads' condition variables whenever
 background-thread support is built, and os_cond_init (os/posix/cond.h) fails, so malloc_init_hard fails and
 allocations fail, where configure's build would wait on the wall clock instead. Darwin has no
 pthread_condattr_setclock, so it is undefined there.
- **glibc:** Without a prefix, the __libc_* functions and __posix_memalign are probed and listed (exempt from private
 renaming) wherever they link, and on Linux the hooks __malloc_hook, __realloc_hook, __free_hook and __memalign_hook
 where they still link (glibc before 2.34), exactly as configure does. jemalloc defines the hooks, and aliases the
 __libc_* functions and __posix_memalign, only where the malloc hooks link on glibc; elsewhere, as with configure,
 these names are listed but not defined.
- **//settings/flags:enable_user_config (--disable-user-config):** On by default, as in the make build: jemalloc reads
 options from the MALLOC_CONF environment variable and the /etc/malloc.conf link, both renamed by a prefix. Set it to
 False, or jemalloc()'s user_config to "False", to read neither, leaving the options compiled in through
 //settings/flags:malloc_conf and an application's own malloc_conf.
- **//settings/flags:enable_dss (--disable-dss):** On by default: as in the make build, jemalloc can allocate from the
 data segment with sbrk(2) wherever the target links sbrk and does not deprecate it (every Apple OS does). Set it to
 False, or jemalloc()'s dss to "False", to never call sbrk, as when something else in the process owns the data
 segment.
- **//settings/flags:enable_pageid (--enable-pageid):** Off by default. On, jemalloc names its anonymous mappings
 (jemalloc_pg, or jemalloc_pg_overcommit) in /proc/<pid>/maps, where the target has prctl; Linux 5.17 or later with
 CONFIG_ANON_VMA_NAME applies the names, and other kernels ignore them. jemalloc()'s pageid sets it per target.
- **//settings/flags:enable_cxx (--disable-cxx):** True by default with every C++ compiler, cl and clang-cl included.
 With it jemalloc's C++ support (src/jemalloc_cpp.cpp) is compiled, so a program linking @jemalloc gets jemalloc's
 operator new and delete rather than the C++ runtime's (with cl and clang-cl, rather than the CRT's). On Windows that
 replacement holds per module, and malloc stays with the CRT, so memory one module allocates with new must be deleted
 by a module that links @jemalloc too; a program that hands such memory to a DLL without jemalloc's operators needs
 False. configure turns C++ off for cl whatever --enable-cxx says, because its C++14 check reads __cplusplus, which cl
 reports as 199711L; this build does not follow that check, a deliberate difference. False is the opt-out and keeps
 the runtime's operators. jemalloc()'s cxx sets it per target.
- **//settings/flags:enable_cxx_infallible_new (--enable-cxx-infallible-new):** Off by default. On, the throwing
 operator new aborts with the requested size logged when an allocation fails, instead of calling the new handler and
 throwing std::bad_alloc, which with LTO lets the compiler drop exception cleanup in its callers; the nothrow forms still
 return null. As with configure, it takes effect only with //settings/flags:enable_cxx. jemalloc/jemalloc.h always
 defines JEMALLOC_INFALLIBLE_NEW, to 1 when it is on and to 0 otherwise. jemalloc()'s cxx_infallible_new sets it per
 target.
- **//settings/flags:enable_force_getenv (--enable-force-getenv):** Off by default, so jemalloc reads MALLOC_CONF with
 secure_getenv, or ignores it in a setuid or setgid process where only issetugid is available. On, it always reads it
 with getenv, including in privileged processes. jemalloc()'s force_getenv sets it per target.
- **//settings/flags:enable_experimental_sdt (--enable-experimental-sdt):** Off by default. On, jemalloc emits USDT
 probes: systemtap's, where the toolchain links configure's <sys/sdt.h> program (a nested function, so GCC only), or
 else jemalloc's own on Linux x86_64, aarch64 and 32-bit Arm and on Android aarch64 and x86_64. As with configure, any
 other Linux or Android CPU gets no probes and no error, and any other platform fails the build. jemalloc()'s
 experimental_sdt sets it per target.
- **//settings/flags:enable_experimental_fiber_safe_tls (--enable-experimental-fiber-safe-tls):** Off by default. On,
 jemalloc's TSD get and set accessors recompute the thread-local data's address through an out-of-line function behind
 an optimization barrier, so a fiber or stackful coroutine that migrates between threads across a user-space context
 switch does not keep using the previous thread's tcache, which the compiler may otherwise cache when it inlines the
 allocator into the caller, as whole-program LTO does. It covers only those accessors, not every thread-local access
 jemalloc or its caller makes; see INSTALL.md. The accessor is GNU inline assembly, so the build fails with a compiler
 that does not define __GNUC__, such as cl. jemalloc()'s experimental_fiber_safe_tls sets it per target.
- **//settings/flags:experimental_sys_process_madvise (--with-experimental-sys-process-madvise):** Empty by default.
 jemalloc uses process_madvise (for batched purging, which opt.process_madvise_max_batch enables) where the C library's
 headers declare SYS_process_madvise and PIDFD_SELF. Set it to the system call number, for example 440, to use it on a
 Linux target whose headers lack them, as configure does wherever its probe fails and madvise links. The value is
 written into the header as is. Unlike configure, the build also writes EXPERIMENTAL_SYS_PROCESS_MADVISE_NR where the
 probe passes or madvise is missing, where nothing reads it.
- **//settings/flags:enable_prof (--enable-prof):** "no" by default. "libunwind", "libgcc" and "gcc" choose configure's
 backtrace methods.
- **--enable-tsan, --enable-ubsan and --with-cxx-stdlib:** configure's sanitizer options only add -fsanitize=thread
 or -fsanitize=undefined to the compile and link flags, and --with-cxx-stdlib only chooses -lstdc++ or -lc++. Here the
 C and C++ toolchain owns both, so there are no flags for them: enable a sanitizer through the toolchain's features or
 --copt and --linkopt, and choose the C++ standard library with the C++ toolchain.

Settings whose "__auto__" default jemalloc resolves for the target platform:
- //settings/flags:enable_lazy_lock
- //settings/flags:enable_zone_allocator
- //settings/flags:jemalloc_prefix
- //settings/platform:lg_page
- //settings/platform:lg_vaddr

The optional public functions (memalign, valloc, pvalloc, malloc_size) are exported exactly where configure would export
them: where the target's toolchain links them, as the configured headers record.

## Fidelity with upstream

The upstream build generates several headers with shell, awk and sed scripts, run by configure and make on the host.
Here Bazel generates them with small C++ tools, so a module that depends on `@jemalloc` needs only its C and C++
toolchain: no host shell, awk or sed. As in configure, the public symbols include optional functions only where the
configured headers define the matching macro, so the headers built from them are written when the build runs.
private_namespace.h comes from listing the library's symbols with the toolchain's `nm`, or with dumpbin for MSVC, as
upstream's private_symbols.awk reads both. From dumpbin it also renames two kinds of external definition that awk skips:
symbols in a section whose hex number begins with a letter, and communal symbols, which nm lists as `C` and awk accepts
there. Those are what cl's private_namespace.h adds to upstream's, so its fidelity tests use listings without them.

The upstream scripts are kept, not replaced. Each generated header has a `fidelity_test` in
[tools/fidelity](tools/fidelity) that runs the unmodified upstream script, as configure.ac invokes it, on the
same inputs and with the same settings, and fails if the outputs differ. The scripts run with hermetic gawk, grep, sed
and coreutils, which are dev dependencies: they are fetched for this repository's tests and never for consumers. The
`upstream-oracle` CI job goes further, building the upstream release with configure and make and comparing every
script-generated header, and the public and wrapped symbol lists, with the Bazel build's.

When upgrading jemalloc, a failing fidelity test means an upstream script changed and its Bazel counterpart must
follow.

## Validated Platforms

Tested in CI with the latest Bazel 8.x and 9.x:

- Ubuntu 22.04, 24.04 & 26.04 (x86_64)
- Ubuntu 24.04 (aarch64)
- MacOS 15 & 26 (arm64)

The minimum supported Bazel, 8.5.0, is tested on Ubuntu 24.04 (x86_64), on Windows Server 2025 with MSVC and, for the
host toolchain examples only, MacOS 15.
Windows Server 2025 (x86_64) is tested with MSVC (msvc-cl), host toolchain examples included, on the latest Bazel 8.x
and 9.x, and with clang-cl on the latest 9.x, without the fidelity checks, whose gawk, grep and sed dev dependencies do
not build for Windows.
Profiling (`--config=prof-*`) is tested on Linux only.
Debug is tested with prof-libgcc, log on and cache oblivious off, on Ubuntu 24.04 (x86_64) with the latest Bazel 9.x
only. The host toolchain examples build a jemalloc() target with debug on every tested platform.

## Known Issues

- **Windows:**
  - MinGW-w64 builds are cross-compiled in CI with hermetic LLVM, from Linux and macOS, but their programs are not run.
    MSYS2's mingw-gcc is not built in CI.
  - With cl and clang-cl, `@jemalloc` is a static library only: its API is declared with an empty `JEMALLOC_EXPORT`,
    so a DLL made from it with `cc_shared_library` exports none of it.
- **macOS 11 and earlier (arm64):** 5.4.0 reads the current CPU number on arm64 Darwin from the low bits of tpidr_el0
  (include/jemalloc/internal/os/darwin/cpu.h), which assumes macOS 12 or later; on macOS 11 the CPU number is kept
  elsewhere and is misread. Only percpu_arena (MALLOC_CONF's `percpu_arena:percpu` or `percpu_arena:phycpu`) reads it,
  and that is off by default, so it matters only where percpu_arena is turned on.
- **FreeBSD:** configure's FreeBSD settings are translated (lazy lock, -D_BSD_SOURCE for probes), but nothing has
  been built on FreeBSD.

## How the registry entry is produced

The registry entry does not fetch the repository above. It fetches upstream's release tarball (for 5.4.0,
`jemalloc-5.4.0.tar.bz2` from jemalloc's GitHub releases) and adds the Bazel build to it:

- **overlay/** holds every committed file the tarball lacks: the BUILD and .bzl files, MODULE.bazel, settings/, tools/,
  examples/ and this README. The repository's own tooling, listed in `.bcr/fork_only.txt`, stays out.
- **patches/** holds one patch for each upstream file the repository edits, the difference between the committed file
  and the tarball's (except root dotfiles listed in `.bcr/fork_only.txt`, which ship as upstream's). Where a release's
  tarball ships files the build must not see, a branch adds `.bcr/tarball_removals.txt`, and patches/ also holds
  `tarball_removals.patch`, which deletes the files it lists. The exporter generates it from the tarball's own bytes,
  and each listed file must be one the repository does not commit.

The registry serves every tarball file the entry does not delete, so each one must be accounted for: committed by the
repository, listed for removal, or listed in `.bcr/release_generated.txt` as a file upstream's release process generates
and the repository does not commit, which ships as the tarball has it. Deleting or renaming an upstream file therefore
takes a list entry too, or the export stops; both lists must name only tarball files the repository does not commit.

`.github/scripts/export_bcr_entry.py` writes the entry into a registry checkout from a committed ref. It writes
nothing unless the tarball, overlay and patches, with the patches applied by GNU patch, rebuild the tree that ref
defines, file for file, byte for byte and mode for mode. It builds that tree from the ref, not from the tarball: the
ref's content for each file it ships, plus the tarball's copy of each listed release-generated file and of each root
dotfile listed in `.bcr/fork_only.txt`. The tooling in `.bcr/fork_only.txt`, including these lists, stays out. GNU
patch stands in for Bazel's patcher only because the exporter restricts the patches, and the files they touch, to
what Bazel's line-based patcher reproduces exactly: plain ASCII paths, comments that cannot read as patch syntax,
UTF-8 text without CR that ends in a newline, and deletions only of non-empty text files. A patch carries contents
only, so the export also stops if the ref commits an upstream file as a symlink or with another executable bit. It
stops, too, if an entry already in the registry for the same upstream release fetches a different tarball, so a
re-rolled upstream asset cannot slip into a new `.bcr.N`. `.bcr/presubmit.yml` becomes the entry's presubmit.

## Upgrading from 5.3.1

- Bazel 8.5.0 or later is required; Bazel 7 is no longer supported.
- enable_prof=frame_pointer and the .bazelrc prof-frame-pointer config are removed, since upstream removed
 --enable-prof-frameptr.
- //settings/flags:enable_cxx is a bool_flag again, and "__auto__" is rejected, as is jemalloc()'s cxx = "__auto__".
- With cl and clang-cl, a program linking @jemalloc now gets jemalloc's operator new and delete rather than the CRT's,
 per module; see //settings/flags:enable_cxx for memory that crosses a DLL boundary.
- 5.3.1's experimental_infallible_new run-time option is gone upstream; //settings/flags:enable_cxx_infallible_new
 (--enable-cxx-infallible-new) replaces it at build time.
- //settings/platform:lg_page below 8 and lg_hugepage not greater than lg_page now fail analysis, as configure does.
- JEMALLOC_HAVE_RDTSCP is no longer defined on x86_64 macOS, or anywhere; 5.4.0's macOS CPU backend does not read it.

The module's compatibility_level stays 5.

## Contributing

Send changes as pull requests to https://github.com/sallustfire/jemalloc, against the branch for the jemalloc version,
such as `bcr-5.4.0`. Support for a new jemalloc release starts as a new `bcr-<version>` branch.

- Leave upstream's files as upstream ships them where you can. Each edit to one ships to the registry as a patch, so
  edit one only when the Bazel build needs it, and say why in a comment beside the edit.
- A new file ships in the overlay with no further step. List it in `.bcr/fork_only.txt` only if it is tooling for this
  repository, such as CI configuration.
- Run `bazel test //...` at the root and in `examples/host_toolchain` and `examples/hermetic_llvm`. CI runs them on the
  platforms above and builds the upstream release with configure and make to compare.

A release sets `version` in MODULE.bazel to `<upstream>` for the first entry of an upstream release, or to
`<upstream>.bcr.<N>` for a later revision of the Bazel build on the same release, runs
`.github/scripts/export_bcr_entry.py --registry <registry checkout>`, and opens a pull request against the
[Bazel Central Registry](https://github.com/bazelbuild/bazel-central-registry) with the entry it writes.
