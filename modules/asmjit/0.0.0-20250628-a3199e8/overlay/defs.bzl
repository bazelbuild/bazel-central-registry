"""Compiler and linker flags shared by the AsmJit library and its tests."""

# AsmJit requires C++17 (target_compile_features(... cxx_std_17)).
ASMJIT_COPTS = select({
    "@rules_cc//cc/compiler:clang-cl": ["/std:c++17"],
    "@rules_cc//cc/compiler:msvc-cl": ["/std:c++17"],
    "//conditions:default": ["-std=c++17"],
})

ASMJIT_LINKOPTS = select({
    "@platforms//os:linux": [
        "-lpthread",
        "-lrt",
    ],
    "//conditions:default": [],
})
