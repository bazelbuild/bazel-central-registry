load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

exports_files(
    [
        "config.h.in",
        "ngspice.sh.in",
    ],
    visibility = ["//visibility:private"],
)

cc_binary(
    name = "runtime_tool",
    srcs = ["runtime_tool.cc"],
    copts = ["-std=c++17"],
    visibility = ["//:__pkg__"],
)
