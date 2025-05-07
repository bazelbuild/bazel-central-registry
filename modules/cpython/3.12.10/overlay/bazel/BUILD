package(default_visibility = ["//:__subpackages__"])

load("//bazel:utils.bzl", "bootstrap_py_binary")

exports_files([
    "zip_stdlib.py",
    "gen_2to3_grammar.py",
])

bootstrap_py_binary(
    name = "zip-stdlib",
    srcs = ["zip_stdlib.py"],
    main = "zip_stdlib.py",
    visibility = ["//visibility:public"],
)

# This is a substitute for Modules/getbuildinfo.c.
cc_library(
    name = "buildinfo",
    srcs = ["bazel_buildinfo.c"],
    linkstamp = "bazel_linkstamp.cc",
    visibility = ["//visibility:public"],
)
