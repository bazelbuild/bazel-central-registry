"""Bootstrap helpers for ICU data-generation tools.

ICU data generation creates a circular dependency:
  tools → toolutil → icuuc → ICU .dat file → tools

All tool binaries must be compiled against stub ICU data to break this cycle.
bootstrap_cc_binary() is a drop-in for cc_binary that compiles the target and
all its transitive deps with //icu4c/source:bootstrapping = True, causing icuuc
to use stub data instead of the real .dat file.

The -std=c++17 extension ensures C++17 is available in the exec configuration
(where --cxxopt is not inherited from the target config).
"""

load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@with_cfg.bzl//:with_cfg.bzl", "with_cfg")

bootstrap_cc_binary, _ = (
    with_cfg(cc_binary)
        .set(Label("//icu4c/source:bootstrapping"), True)
        .extend("cxxopt", ["-std=c++17"])
        .build()
)
