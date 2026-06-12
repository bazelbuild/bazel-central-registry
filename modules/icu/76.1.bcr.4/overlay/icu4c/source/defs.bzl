"""Internal Starlark helpers for the ICU module.

The rules here are implementation details of how this module is structured;
they apply ICU-specific configuration transitions that aren't meaningful in
isolation. Load visibility is restricted to this module's own packages so
consumers don't accidentally rely on them.
"""

load("@rules_cc//cc:defs.bzl", _cc_binary = "cc_binary", _cc_shared_library = "cc_shared_library")
load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")
load("@with_cfg.bzl//:with_cfg.bzl", "with_cfg")

visibility(["//..."])

# ICU data generation creates a circular dependency:
#   tools -> toolutil -> icuuc -> ICU .dat file -> tools
#
# All tool binaries must be compiled against stub ICU data to break this cycle.
# bootstrap_cc_binary() is a drop-in for cc_binary that compiles the target and
# all its transitive deps with //icu4c/source:bootstrapping = True, causing
# icuuc to use stub data instead of the real .dat file.
#
# We also force //icu4c/source:enable-shared = False here. Bootstrap tools are
# always statically linked against icuuc/toolutil, regardless of how the outer
# build wants to consume ICU. Without this, when a cc_shared_library ancestor
# has flipped 'enable-shared=True' under its subtree, that Starlark flag
# survives the run_binary -> tool (cfg = "exec") transition into the data-gen
# tool's config.
#
# On Windows, the windows-static-build select then misses and 'udata.cpp' gets
# compiled with U_DATA_API = dllimport, leaving `__imp_icudt<v>_dat` unresolved
# at link time. Pinning 'enable-shared=False' at the bootstrap boundary states
# the invariant explicitly and is independent of how Bazel propagates
# user-defined build settings across exec transitions.
bootstrap_cc_binary, _bootstrap_internal = (
    with_cfg(_cc_binary)
        .set(Label("//icu4c/source:bootstrapping"), True)
        .set(Label("//icu4c/source:enable-shared"), False)
        .build()
)

# cc_shared_library() is a drop-in for rules_cc's cc_shared_library that flips
# //icu4c/source:enable-shared=True under its transitive deps via a per-target
# transition. This causes the underlying cc_library targets to be recompiled
# with the dllexport/dllimport markers intact, so the resulting DLL on Windows
# actually exports symbols (and Linux/macOS shared libs work for free, since
# ICU's macros already do the right thing there). Consumers can depend on the
# shared-library targets directly without touching the enable-shared flag.
#
# extra_providers = [CcSharedLibraryInfo] is required so cross-shared-lib
# 'dynamic_deps' resolution sees the provider.
cc_shared_library, _shared_internal = (
    with_cfg(_cc_shared_library, extra_providers = [CcSharedLibraryInfo])
        .set(Label("//icu4c/source:enable-shared"), True)
        .build()
)
