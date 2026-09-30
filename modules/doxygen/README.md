# Doxygen

This module adds a native Bazel overlay to the upstream Doxygen source release
and exposes the resulting executable as `@doxygen//:doxygen`.

The overlay runs Doxygen's Python generators, Flex scanners, and Bison parsers
as Bazel actions, with no release binary or host-installed parser generator.
The registered `@doxygen//:toolchain_type` implementations are constrained by
execution platform: x86-64 is selected on Linux x86-64 workers and ARM64 on
Linux ARM64 workers.

The native build uses the BCR `rules_cc`, `rules_python`, `bison`, and `flex`
modules and intentionally leaves Doxygen's optional libclang support disabled.
