"""Compiler and linker flags shared by the AsmJit library and its tests."""

# AsmJit requires C++17 (target_compile_features(... cxx_std_17)).
ASMJIT_COPTS = select({
    Label("@rules_cc//cc/compiler:clang-cl"): ["/std:c++17"],
    Label("@rules_cc//cc/compiler:msvc-cl"): ["/std:c++17"],
    "//conditions:default": ["-std=c++17"],
})

ASMJIT_LINKOPTS = select({
    Label("@platforms//os:linux"): [
        "-lpthread",
        "-lrt",
    ],
    "//conditions:default": [],
})
