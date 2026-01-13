# Git (Bazel module)

This is a community-maintained setup to build Git (and libgit) using Bazel.

## Release notes

### 2.52.0

- Tests are successfully validated on macOS ARM64 and Linux x86. We do not currently validate Windows in CI; contributions to enable or stabilize Windows support are welcome.
- Python, Perl, and shell toolchains are currently hard-coded in the Bazel setup (not yet pluggable via toolchain resolution).
- t3900 is disabled explicitly on MacOS due to a problem with lib iconv shipped on MacOS 14 and 15. This will be fixed in a future git release and should be re-enabled then.
