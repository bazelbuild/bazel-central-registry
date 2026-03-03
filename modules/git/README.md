# Git (Bazel module)

This is a community-maintained setup to build Git (and libgit) using Bazel.

## Release notes

### 2.53.0

- Rebased Bazel integration on top of upstream Git 2.53.0.
- Fixed Bazel 9 / `rules_cc` compatibility by adding explicit `@rules_cc//cc:defs.bzl` loads in subpackage BUILD files and removing the global `-I.` compile flag.
- Added macOS iconv compatibility settings in Bazel flags (`-DICONV_RESTART_RESET` and explicit `libiconv` linkopts for common Homebrew paths).
- Kept source files unmodified by adding Bazel-only compatibility include shims under `contrib/bazel/includes/` (`//contrib/bazel:angle_include_shims`) instead of patching C sources.
- Fixed external-workspace consumption (`bazel_dep` + override) by removing repository-root assumptions in Bazel genrules (`command-list.h`, `hook-list.h`, `config-list.h` generation).
- Updated Bazel wiring for upstream source layout changes in 2.53.0 (`odb/streaming.c` and `odb/streaming.h`).
- Updated test coverage for 2.53.0 by adding `t1311-config-optional`, `t5565-push-multiple`, and `t8015-blame-diff-algorithm`, and re-enabled `t3900-i18n-commit`.
- Synced overlay structure with upstream by adding `overlay/.gitignore` and removing the duplicated `overlay/MODULE.bazel`.
- Updated `libexpat` to `2.7.1.bcr.1` (no local patch override).
- Updated BCR presubmit matrix to include Bazel 9.x and macOS ARM64 in addition to existing Linux coverage.

### 2.52.0

- Tests are successfully validated on macOS ARM64 and Linux x86. We do not currently validate Windows in CI; contributions to enable or stabilize Windows support are welcome.
- Python, Perl, and shell toolchains are currently hard-coded in the Bazel setup (not yet pluggable via toolchain resolution).
- t3900 is disabled explicitly on MacOS due to a problem with lib iconv shipped on MacOS 14 and 15. This will be fixed in a future git release and should be re-enabled then.
