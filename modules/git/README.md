# Git (Bazel module)

This is a community-maintained setup to build Git (and libgit) using Bazel.

## Release notes

### v2.52.0

- Tests are successfully validated on macOS ARM64 and Linux x86. We do not currently validate Windows in CI; contributions to enable or stabilize Windows support are welcome.
- macOS builds depend on the exec platform having Homebrew's libiconv available (the build expects it to be provided externally).
- Python, Perl, and shell toolchains are currently hard-coded in the Bazel setup (not yet pluggable via toolchain resolution).
