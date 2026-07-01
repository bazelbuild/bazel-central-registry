load("@rules_cc//cc:cc_library.bzl", "cc_library")

cc_library(
    name = "cereal",
    hdrs = glob([
      "include/cereal/**/*.hpp",
      "include/cereal/**/*.h",
    ]),
    includes = ["include"],
    visibility = ["//visibility:public"],
)
