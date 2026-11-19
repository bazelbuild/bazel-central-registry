# mimalloc 3.5.3 Bazel build settings

Qualification for `mimalloc@3.5.3.bcr.1`, pinned to the v3.5.3 release archive
(SHA-256 `43857a9e4f26412e970cbe49635d0465c2de6e77a697ce3d4b926a473d1045ca`,
source commit `d4881d338125e1cb7c47ba4cfb398d6f7c0c8d45`). Sources:
[CMakeLists.txt](https://github.com/microsoft/mimalloc/blob/d4881d338125e1cb7c47ba4cfb398d6f7c0c8d45/CMakeLists.txt),
[types.h](https://github.com/microsoft/mimalloc/blob/d4881d338125e1cb7c47ba4cfb398d6f7c0c8d45/include/mimalloc/types.h),
[options.c](https://github.com/microsoft/mimalloc/blob/d4881d338125e1cb7c47ba4cfb398d6f7c0c8d45/src/options.c),
and [Unix prim.c](https://github.com/microsoft/mimalloc/blob/d4881d338125e1cb7c47ba4cfb398d6f7c0c8d45/src/prim/unix/prim.c).

The table covers every `MI_*` CMake cache entry in that source. ON/OFF below
means CMake boolean values, including its usual true/false spellings. CMake
lists enum choices with `set_property(CACHE ... STRINGS ...)` but does not
validate them; the Bazel string flags validate their supported values.
`auto` in a Bazel flag preserves the existing overlay's source defaults.

| CMake setting; default | Accepted values | Constraint and actual build effect | Bazel equivalent or omission |
| --- | --- | --- | --- |
| `MI_OVERRIDE`; ON | ON/OFF | Exports standard malloc/free; gates Apple zone/interpose behavior and compiler `-fno-builtin-malloc`. | Existing public `mimalloc` target through `malloc = "@mimalloc"` or `--custom_malloc=@mimalloc`. OFF would invalidate that target's override contract; no non-override library target is exposed. |
| `MI_SECURE`; OFF | OFF/ON/FULL | ON defines `MI_SECURE=4`; FULL defines `MI_SECURE=5` for per-page guard pages; changes CMake artifact name. | `--@mimalloc//:secure=off\|on\|full`; Bazel label stays stable. |
| `MI_DEBUG`; DEFAULT | DEFAULT/OFF/ON/INTERNAL/FULL | DEFAULT follows build type (a generator expression in multi-config CMake); OFF adds `NDEBUG=1`; ON/INTERNAL/FULL define `MI_DEBUG=1/2/3`. | `debug=auto\|off\|on\|internal\|full`; `auto` preserves the existing Bazel source default. |
| `MI_GUARDED`; DEFAULT | DEFAULT/OFF/ON/FULL | DEFAULT becomes FULL when CMake's current `MI_DEBUG` is on, else OFF; explicit values define `MI_GUARDED=0/1/2`. Multi-config DEFAULT is OFF because CMake sets `MI_DEBUG=OFF` after adding its generator expression. | `guarded=auto\|off\|on\|full`. With an explicit non-OFF `debug`, `auto` becomes FULL; with `debug=auto`, it preserves source behavior. |
| `MI_STATS`; DEFAULT | DEFAULT/OFF/ON/FULL | DEFAULT becomes FULL when CMake's current `MI_DEBUG` is on, ON otherwise; values define `MI_STATS=0/1/2`. Multi-config DEFAULT is ON. | `stats=auto\|off\|on\|full`, including explicit-debug precedence. |
| `MI_PROFILE`; DEFAULT | DEFAULT/OFF/ON/FULL | DEFAULT becomes FULL when CMake's current `MI_DEBUG` is on, ON otherwise; values define `MI_PROFILE=0/1/2`. Multi-config DEFAULT is ON. | `profile=auto\|off\|on\|full`, including explicit-debug precedence. |
| `MI_FREE_IS_CHECKED`; DEFAULT | DEFAULT/OFF/SHARED/ON | Default under secure mode adds `MI_FREE_IS_CHECKED=1`; ON adds it; SHARED adds it only to the shared-library compilation. Secure mode itself still checks frees when OFF. | `free_is_checked=auto\|off\|on`. SHARED omitted: this overlay compiles one library for static and shared targets, so it cannot apply a shared-only definition. |
| `MI_ALLOW_THP`; DEFAULT | DEFAULT/OFF/ON/FULL | Linux/Android only: DEFAULT becomes FULL on Linux, OFF on Android; FULL/ON/OFF define `MI_DEFAULT_ALLOW_THP=2/1/0`. FULL also prevents purge from splitting THP. | `allow_thp=default\|off\|on\|full`; platform `config_setting`s keep definitions private and absent elsewhere. |
| `MI_XMALLOC`; OFF | ON/OFF | ON defines `MI_XMALLOC=1`, making allocation failure abort by default. | `xmalloc=true`. |
| `MI_SHOW_ERRORS`; OFF | ON/OFF | ON defines `MI_SHOW_ERRORS=1`; errors also default on in source debug builds. | `show_errors=true`. |
| `MI_SKIP_COLLECT_ON_EXIT`; OFF | ON/OFF | ON defines `MI_SKIP_COLLECT_ON_EXIT=1`, skipping collection on process exit. | `skip_collect_on_exit=true`. |
| `MI_PADDING`; OFF | ON/OFF | ON defines `MI_PADDING=1`; otherwise source enables it for secure/debug/tracking modes. | `padding=auto\|on\|off`; `auto` leaves source behavior, `off` defines 0. |
| `MI_NO_PADDING`; OFF | ON/OFF | ON takes precedence over `MI_PADDING` and defines `MI_PADDING=0`. | `padding=off`; no duplicate negative flag. |
| `MI_OSX_ZONE`; ON | ON/OFF | With override on Apple, adds `src/prim/osx/alloc-override-zone.c` and defines `MI_OSX_ZONE=1`. | `osx_zone=false` removes source and definition on macOS. |
| `MI_OSX_INTERPOSE`; ON | ON/OFF | With override on Apple, defines `MI_OSX_INTERPOSE=1`; interpose code also requires a shared export build. | Omitted: existing macOS `mimalloc-lib` compiles with `MI_STATIC_LIB` even when wrapped in `cc_shared_library`; toggling the definition would not enable/disable its shared interpose code. A separate shared compilation path is needed. |
| `MI_WIN_REDIRECT`; ON | ON/OFF | On Windows shared builds, OFF defines `MI_WIN_NOREDIRECT=1` and removes the redirect import/DLL link and copy. | `win_redirect=false` removes redirect dependencies and adds the private negative definition; static-CRT target selection stays intact. |
| `MI_NO_THP`; OFF | ON/OFF | On Linux/Android, ON forces `MI_ALLOW_THP=OFF` before definitions are emitted. It does **not** define `MI_NO_THP` in this release's CMake build. | `allow_thp=off`; one enum gives the same effective value and avoids contradictory flags. |
| `MI_FREE_USE_PAGEMAP`; OFF | ON/OFF | ON defines `MI_FREE_USE_PAGEMAP=1`; CMake also forces it ON for WASI. | Omitted: the existing overlay has no WASI-specific implementation path or validation for this allocation strategy; a toggle would miss the forced WASI behavior. |
| `MI_LIBC_MUSL`; OFF | ON/OFF | Defines `MI_LIBC_MUSL=1`; changes static/shared TLS compiler models unless LOCAL_DYNAMIC is selected. | Omitted: libc choice and TLS model must agree with the C/C++ toolchain and final link. The overlay has no musl toolchain constraint. |
| `MI_USE_CXX`; DEFAULT | DEFAULT/OFF/ON | Changes source language/driver to C++; DEFAULT chooses C++ for MSVC, Intel, and clang-cl. | Omitted: language selection belongs to Bazel C/C++ source rules and toolchain; the current target compiles C. |
| `MI_OPT_ARCH`; DEFAULT | DEFAULT/OFF/ON/avx2/armv8.1/armv8.3/rva22/rva23/rv64gcb_zacas/rv64gcb_zacas_zalasr | DEFAULT turns ON for arm64. ON maps by architecture (Apple arm64 armv8.3, other arm64 armv8.1, x64 AVX2, RISC-V ISA); explicit and unknown truthy values emit `-march` or MSVC `/arch`. | Omitted: ISA must be selected by target platform and C/C++ toolchain, especially in cross and Apple multi-arch builds. An overlay flag could emit instructions unavailable to a selected target. |
| `MI_OPT_SIMD`; OFF | ON/OFF | Defines `MI_OPT_SIMD=1` only when `MI_OPT_ARCH` produced architecture flags. | Omitted with `MI_OPT_ARCH`; SIMD must follow the toolchain's proven ISA support. |
| `MI_TRACK`; OFF | OFF/ASAN/VALGRIND/ETW | Valgrind needs headers; ASAN needs headers and compile/link sanitizer flags, and is disabled with Apple override; ETW is Windows-only. Emits tracking definitions and changes CMake output names. | Omitted: Valgrind/ASAN lack declared headers and sanitizer runtime/final-link integration; ETW's Windows provider and link path are unqualified. A definition alone does not establish working tracking. |
| `MI_DEBUG_TSAN`; OFF | ON/OFF | Clang-only `MI_TSAN=1`, `-fsanitize=thread -g -O1` at compile and link. | Omitted: needs a sanitizer toolchain/runtime and final-binary link support. |
| `MI_DEBUG_UBSAN`; OFF | ON/OFF | Debug and Clang++ only; `MI_UBSAN=1`, undefined sanitizer compile/link flags, C++ source compilation. | Omitted: needs C++ compilation, debug-mode and sanitizer runtime/link integration. |
| `MI_TLS_MODEL`; DEFAULT | DEFAULT/LOCAL/PTHREADS/LOCAL_DYNAMIC/WIN32/FIXED | Selects TLS implementation macros; LOCAL_DYNAMIC also needs `-ftls-model=local-dynamic`, otherwise CMake chooses initial-exec on supported Unix. FIXED requires a process-wide unique fixed slot; LOCAL on macOS warns for dynamic override. | Omitted: this single static-configured target cannot preserve all platform and shared-link TLS combinations; fixed slots require application coordination. Toolchain TLS flags alone would not select the source implementation. |
| `MI_TLS_RECURSE_GUARD`; OFF | ON/OFF | Defines `MI_TLS_RECURSE_GUARD=1`, relevant only to LOCAL TLS. | Omitted with `MI_TLS_MODEL`; standalone flag has no useful effect for default macOS/Windows models. |
| `MI_WIN_INIT`; DEFAULT | DEFAULT/CRT_TLS/RAW_DLLMAIN/TLS_DLLMAIN/FLS | Windows initialization strategy; non-default variants define raw or TLS DllMain or FLS code paths, with potential linker entry-point conflicts. | Omitted: requires Windows DLL/CRT-specific link qualification; RAW_DLLMAIN can conflict with another entry point. |
| `MI_BUILD_SHARED`; ON | ON/OFF | Creates shared output and install/export entries. | Existing target selection: `mimalloc` chooses dynamic on Windows DLL CRT, static otherwise; internal shared target remains a build artifact. |
| `MI_BUILD_STATIC`; ON | ON/OFF | Creates static output and install/export entries. | Existing `mimalloc` alias selects static on non-Windows and Windows static CRT. |
| `MI_BUILD_OBJECT`; ON | ON/OFF | Creates and installs a single `src/static.c` object. | Omitted: the overlay uses an alwayslinked library and does not expose an object distribution target. |
| `MI_BUILD_TESTS`; ON | ON/OFF | Builds upstream tests. | Bazel uses explicit `bazel test` target selection; BCR overlay has consumer tests. |
| `MI_INSTALL_TOPLEVEL`; OFF | ON/OFF | Changes install directories for headers, object, and CMake metadata. | Omitted: Bazel labels/runfiles replace CMake install layout. |
| `MI_SEE_ASM`; OFF | ON/OFF | Compiler-specific assembly files (`-FA` for MSVC/clang-cl, `-save-temps=obj` otherwise). | Omitted: side files are undeclared Bazel outputs; use compiler/action inspection tooling. |
| `MI_EXTRA_CPPDEFS`; empty | Arbitrary semicolon-separated definitions | Prepends definitions to every mimalloc CMake target; later CMake definitions may override them. | Omitted: unrestricted definitions bypass typed validation and precedence, and may alter ABI or need link support. Add a reviewed typed flag for a concrete setting. |
| `MI_NO_USE_CXX`; OFF | ON/OFF | Negated vcpkg setting overrides `MI_USE_CXX` before its DEFAULT resolution. | Omitted with `MI_USE_CXX`; no overlay compatibility user. |
| `MI_NO_OPT_ARCH`; OFF | ON/OFF | Negated vcpkg setting overrides `MI_OPT_ARCH` including arm64 DEFAULT. | Omitted with `MI_OPT_ARCH`; choose target ISA in the toolchain. |
| `MI_NO_DEBUG`; OFF | ON/OFF | Overrides `MI_DEBUG`, adds `NDEBUG=1`. | `debug=off`; no duplicate negated flag. |
| `MI_USE_LIBATOMIC`; OFF | ON/OFF | Deprecated, no longer read after declaration; CMake probes `-latomic` itself. | Omitted; linker/toolchain supplies atomic runtime. |
| `MI_DEBUG_INTERNAL`; OFF | ON/OFF | Deprecated alias for `MI_DEBUG=INTERNAL` when debug is DEFAULT. | Omitted; `debug=internal`. |
| `MI_DEBUG_FULL`; OFF | ON/OFF | Deprecated alias for `MI_DEBUG=FULL` when debug is DEFAULT. | Omitted; `debug=full`. |
| `MI_CHECK_FULL`; OFF | ON/OFF | Deprecated alias for `MI_DEBUG=FULL` when debug is DEFAULT. | Omitted; `debug=full`. |
| `MI_SECURE_FULL`; OFF | ON/OFF | Deprecated alias that forces `MI_SECURE=FULL`. | Omitted; `secure=full`. |
| `MI_TLS_MODEL_LOCAL`; OFF | ON/OFF | Deprecated alias for `MI_TLS_MODEL=LOCAL` when model is DEFAULT. | Omitted with TLS model. |
| `MI_TLS_MODEL_PTHREADS`; OFF | ON/OFF | Deprecated alias for `MI_TLS_MODEL=PTHREADS` when model is DEFAULT. | Omitted with TLS model. |
| `MI_TLS_MODEL_FIXED`; OFF | ON/OFF | Deprecated alias for `MI_TLS_MODEL=FIXED` when model is DEFAULT. | Omitted with TLS model. |
| `MI_LOCAL_DYNAMIC_TLS`; OFF | ON/OFF | Deprecated alias for `MI_TLS_MODEL=LOCAL_DYNAMIC` when model is DEFAULT. | Omitted with TLS model. |
| `MI_WIN_USE_FLS`; OFF | ON/OFF | Deprecated alias for `MI_WIN_INIT=FLS` when init is DEFAULT. | Omitted with Windows init. |
| `MI_WIN_INIT_USE_RAW_DLLMAIN`; OFF | ON/OFF | Deprecated alias for `MI_WIN_INIT=RAW_DLLMAIN` when init is DEFAULT. | Omitted with Windows init. |
| `MI_WIN_INIT_USE_TLS_DLLMAIN`; OFF | ON/OFF | Deprecated alias for `MI_WIN_INIT=TLS_DLLMAIN` when init is DEFAULT. | Omitted with Windows init. |
| `MI_WIN_DIRECT_TLS`; OFF | ON/OFF | Deprecated direct Windows TLS-slot mode, assumes fewer than 64 allocated slots. | Omitted; unsafe process-wide assumption and no overlay compatibility user. |
| `MI_TRACK_VALGRIND`; OFF | ON/OFF | Deprecated alias for `MI_TRACK=VALGRIND`, highest tracking-alias precedence. | Omitted with tracking. |
| `MI_TRACK_ASAN`; OFF | ON/OFF | Deprecated alias for `MI_TRACK=ASAN`, after Valgrind. | Omitted with tracking. |
| `MI_TRACK_ETW`; OFF | ON/OFF | Deprecated alias for `MI_TRACK=ETW`, after Valgrind/ASAN. | Omitted with tracking. |
| `MI_OPT_FREE_SMALL`; DEFAULT | DEFAULT/OFF/ON | Deprecated aligned `mi_free_small` path; ON is rejected under secure or guarded mode, OFF defines `MI_OPT_FREE_SMALL=0`. | Omitted: deprecated, mode-dependent internal layout choice with no overlay compatibility user. |

## THP mapping and runtime defaults

`MI_ALLOW_THP` is processed only for Linux and Android. The pinned release's
mapping is:

| Target | DEFAULT | OFF | ON | FULL |
| --- | --- | --- | --- | --- |
| Linux | `MI_DEFAULT_ALLOW_THP=2` | `=0` | `=1` | `=2` |
| Android | `MI_DEFAULT_ALLOW_THP=0` | `=0` | `=1` | `=2` |
| Other OS | no definition | no definition | no definition | no definition |

`MI_NO_THP=ON` overrides any `MI_ALLOW_THP` value with OFF on Linux/Android.
The Bazel equivalent is `allow_thp=off`. With the Bazel flag at `default`,
the overlay emits the same Linux (2) and Android (0) definitions as CMake;
these agree with the preexisting `src/options.c` fallback. `src/prim/unix/prim.c` uses the runtime
`allow_thp` option to decide whether to advise transparent huge pages.
`local_defines` keeps every emitted definition on mimalloc compilation actions;
consumer sources do not inherit it.

Of the 16 `MI_DEFAULT_*` source macros, only `MI_DEFAULT_ALLOW_THP` has a
dedicated CMake cache setting (`MI_ALLOW_THP`; `MI_NO_THP` is its negated
override). The other 15 are configurable only through `MI_EXTRA_CPPDEFS`:
`MI_DEFAULT_VERBOSE` (0), `MI_DEFAULT_ARENA_EAGER_COMMIT` (2),
`MI_DEFAULT_ARENA_RESERVE` (1 GiB on 64-bit, 128 MiB on 32-bit, expressed in
KiB), `MI_DEFAULT_ARENA_MAX_OBJECT_SIZE` (architecture-dependent 2 GiB or
256 MiB), `MI_DEFAULT_DISALLOW_ARENA_ALLOC` (0),
`MI_DEFAULT_ALLOW_LARGE_OS_PAGES` (0), `MI_DEFAULT_RESERVE_HUGE_OS_PAGES` (0),
`MI_DEFAULT_RESERVE_OS_MEMORY` (0), `MI_DEFAULT_GUARDED_SAMPLE_RATE` (0),
`MI_DEFAULT_PAGEMAP_COMMIT` (1 on Apple with flat page map, otherwise 0),
`MI_DEFAULT_PAGE_MAX_RECLAIM` (-1),
`MI_DEFAULT_PAGE_CROSS_THREAD_MAX_RECLAIM` (32),
`MI_DEFAULT_COLLECT_MERGES_STATS` (1),
`MI_DEFAULT_PHYSICAL_MEMORY_IN_KIB` (4 GiB on 32-bit, 32 GiB on 64-bit,
expressed in KiB), and `MI_DEFAULT_VIRTUAL_ADDRESS_BITS` (0/undefined means
source-detected 47 on x64, 48 on other 64-bit, 32 on 32-bit).

The existing Bazel fastbuild does not define `NDEBUG` or `MI_BUILD_RELEASE`:
source defaults are `MI_DEBUG=2`, `MI_GUARDED=1`, `MI_STATS=2`, and
`MI_PROFILE=1`. CMake with no build type selects Release, then sets debug OFF,
guarded OFF, stats ON, and profile ON. The public flags default to `auto`
where necessary to keep Bazel's existing behavior; explicit `debug` modes
also reproduce CMake's DEFAULT guarded/stats/profile precedence. `-c opt`
supplies Bazel's `NDEBUG` and remains the release-mode choice. CMake's arm64
ISA and initial-exec Unix TLS flags also differ from this overlay; Bazel keeps
the selected toolchain's defaults. Standard CMake cache controls for compiler,
target architecture, build type, and installation map to Bazel toolchains,
platforms, `-c`, and target/runfiles paths respectively.

Examples from a Bzlmod consumer with `bazel_dep(name = "mimalloc", version = "3.5.3.bcr.1")`:

```sh
bazel build //:app --@mimalloc//:secure=full
bazel build //:app --@mimalloc//:debug=full --@mimalloc//:guarded=off
bazel build //:app --@mimalloc//:stats=off --@mimalloc//:profile=off
bazel build //:app --@mimalloc//:allow_thp=on   # Linux or Android
bazel build //:app --@mimalloc//:win_redirect=false # Windows DLL CRT
```
