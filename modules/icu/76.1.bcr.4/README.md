# ICU

## BCR Maintainer Notes

The upstream repository already contains `BUILD.bazel` files, but they are
scoped to ICU's own data-generation pipeline and do not expose the `icuuc`,
`icui18n`, or `icuio` libraries for external consumers. This overlay provides
those consumer-facing targets.

## Library targets

Six top-level aliases expose the public libraries. The first three are
`cc_library` targets for static linking; the `_shared` variants are
`cc_shared_library` targets that produce `libicuuc.so` / `libicuuc.dylib`
/ `icuuc.dll` (and equivalents) for dynamic linking:

| Target                  | Library                                                              |
|-------------------------|----------------------------------------------------------------------|
| `@icu//:icuuc`          | `libicuuc` — Unicode core (static)                                   |
| `@icu//:icui18n`        | `libicui18n` — Collation, formatting, ... (static)                   |
| `@icu//:icuio`          | `libicuio` — stdio-compatible Unicode I/O (static)                   |
| `@icu//:icuuc_shared`   | Shared variant of `icuuc` (`libicuuc.so` / `icuuc.dll` / `.dylib`)   |
| `@icu//:icui18n_shared` | Shared variant of `icui18n`                                          |
| `@icu//:icuio_shared`   | Shared variant of `icuio`                                            |

Each library is compiled as a single monolithic target rather than mirroring
the fine-grained upstream targets.

The shared variants flip `//icu4c/source:enable-shared=True` under their
transitive deps via a per-target transition (in `icu4c/source/defs.bzl`),
which adjusts the API-attribute macros (`U_STATIC_IMPLEMENTATION` etc.) so
the resulting DLL on Windows actually exports its symbols. Static consumers
keep depending on the plain `:icuuc` / `:icui18n` / `:icuio` aliases — the
two variants coexist in the same build.

## C++ standard

Per the [ICU 76 platform support documentation][icu76-platform], ICU4C requires
**C++17**. The presubmit workflows test at C++17 so that any accidental C++20
constructs introduced in the overlay are caught early.

[icu76-platform]: https://unicode-org.github.io/icu/download/76.html#icu4c-platform-support

## ICU data

ICU requires a data file (`icudt<version>l.dat`) to function. Two build modes
are selectable via `--@icu//:data-mode`:

**`prebuilt` (default)** — fetches the pre-built `.dat` from the ICU GitHub
release asset (`icu4c-*-data.zip`).

**`source`** — compiles ICU data from the upstream source files using
bootstrap-built ICU tools. Slower on the first build but fully reproducible
from source. On Linux and macOS, `genccode` produces a `.S` assembly file. On
Windows, where the assembler output format is not supported, it produces a
portable `.c` byte-array file instead.

In both modes `genccode` converts the `.dat` into a compiled symbol
(`icudt<ver>l_dat`) that is statically linked into the `icudata` cc_library
and resolved by `udata.cpp` directly in memory without a filesystem lookup at
runtime.

## Bootstrapping

Building ICU data from source creates a circular dependency:

```
icuuc  →  .dat file  →  ICU tools (genrb, pkgdata, ...)  →  icuuc
```

This is broken by a Starlark [configuration transition][transition] in
`icu4c/source/defs.bzl`. `bootstrap_cc_binary` is a drop-in for
`cc_binary` that applies `//icu4c/source:bootstrapping = True` to the target
and its entire transitive dependency graph, causing `icuuc` to link against
stub data (`//icu4c/source/stubdata`) instead of the real `.dat` file.

Only tools that are part of the data-generation pipeline use
`bootstrap_cc_binary`. User-facing tools (e.g. `derb`) remain plain
`cc_binary` targets so they link the real ICU data.

[transition]: https://bazel.build/extending/config#user-defined-transitions

## License metadata

The root package declares `license()` and `package_info()` targets using
[`rules_license`][rules-license], covering all targets in the module under the
[ICU license][icu-license].

[rules-license]: https://github.com/bazelbuild/rules_license
[icu-license]: https://github.com/unicode-org/icu/blob/main/LICENSE

## Patches

**`icu4c_source_test.patch`** — The upstream test harnesses use `U_TOPSRCDIR` /
`U_TOPBUILDDIR` to locate test data, which are unavailable in a Bazel sandbox.
This patch redirects those lookups to Bazel runfiles via three compile-time
macros:

| Macro                          | Points to                                      |
|--------------------------------|------------------------------------------------|
| `BAZEL_ICU_TESTDATA_SRC_DIR`   | `icu4c/source/test/testdata/` (test resources) |
| `BAZEL_ICU_DATA_SRC_DIR`       | `icu4c/source/data/` (unidata, sprep)          |
| `BAZEL_ICU_SHARED_TESTDATA_DIR`| `testdata/` (top-level, e.g. message2 JSON)    |

**`messageformat2test_icu_fix.patch`** — Adds a missing
`void messageFormat1Tests(void);` declaration to the `TestMessageFormat2` class
in `messageformat2test.h`, fixing a compiler error when
`messageformat2test.cpp` is included in the build.

**`databuilder_no_shell.patch`** — Replaces the `shell=True` /
`cmd.exe`-then-PowerShell invocation path in `icutools/databuilder` with a
direct `subprocess.call(argv, shell=False)`. The `windows-exec` mode's
`writePoolBundle` command (~600 locale filenames) overflows cmd.exe's
8191-character limit; upstream's PowerShell fallback then mangles argument
quoting (especially trailing backslashes), producing a missing or unusable
`pool.res` that breaks every subsequent `--usePoolBundle` command. Going
straight to `CreateProcess` bypasses both shells.

**`testidn_path_null_term.patch`** — Fixes an upstream null-termination
bug in `testidn.cpp`'s `testData()`. After
`*basename++ = U_FILE_SEP_CHAR;` the buffer is left non-null-terminated;
the next `uprv_strlen` reads past the intended end into uninitialised
`malloc` memory, and the resulting path is corrupted. The bug is dormant
on the upstream Makefile build (where the source-dir ends with
`U_FILE_SEP_CHAR` and the conditional append never fires) but surfaces on
Windows under Bazel because the runfiles dir uses `/` separators.

## Tests

The upstream ICU test suites (`cintltst`, `intltest`, `iotest`) are Bazelfied
in `icu4c/source/test/`. Three lightweight functional tests are also provided:

| Test                                          | What it checks                    |
|-----------------------------------------------|-----------------------------------|
| `@icu//icu4c/source/test:break-iterator-test` | Data loading + BreakIterator      |
| `@icu//icu4c/source/test:collation-test`      | Collation with locale data        |
| `@icu//icu4c/source/test:locale-test`         | Resource-bundle locale resolution |
