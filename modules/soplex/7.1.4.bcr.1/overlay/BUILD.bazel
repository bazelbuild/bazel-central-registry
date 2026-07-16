# Description:
# Soplex is a LP solver, a common tool in Operations Research.

cc_library(
    name = "soplex",
    srcs = glob(
        ["src/soplex/*.cpp"],
        exclude = ["src/git_hash.cpp"],
    ),
    hdrs = glob(
        [
            "src/soplex/*.h",
            "src/soplex/*.hpp",
        ],
    ) + [
        "src/soplex.h",
        "src/soplex.hpp",
        "src/soplex/git_hash.cpp",
    ],
    copts = select({
        "@platforms//os:windows": ["/utf-8"],
        "//conditions:default": [],
    }),
    includes = ["src"],
    visibility = ["//visibility:public"],
    deps = [
        "@boost.multiprecision",
        "@boost.serialization",
        "@fmt",
        "@zstr",
    ],
)

cc_binary(
    name = "soplex_interactive",
    srcs = ["src/soplexmain.cpp"],
    copts = select({
        "@platforms//os:windows": ["/utf-8"],
        "//conditions:default": [],
    }),
    deps = [
        ":soplex",
        "@boost.multiprecision",
        "@zlib",
    ],
)
