load("@rules_license//rules:license.bzl", "license")

package(
    default_applicable_licenses = [":license"],
    default_visibility = ["//visibility:public"],
)

license(
    name = "license",
    package_name = "toybox",
    license_kinds = ["@rules_license//licenses/spdx:0BSD"],
)


COPTS = [
    "-I.",
    "-funsigned-char",
    "-w",  # const qualifiers are dropped all over the place
    "-Wundef",
    "-Wno-char-subscripts",
    "-Os",
    "-ffunction-sections",
    "-fdata-sections",
    "-fno-asynchronous-unwind-tables",
    "-fvisibility=hidden",
]

cc_library(
    name = "toybox_helper_lib",
    srcs = glob([
        "lib/*.c",
        "lib/*.h",
    ]) + [
        "generated/config.h",
        "generated/flags.h",
        "generated/globals.h",
        "generated/help.h",
        "generated/newtoys.h",
        "generated/tags.h",
        "generated/zhelp.h",
        "toys.h",
    ],
    copts = COPTS,
    features = [
        "-parse_headers",
    ],
    #includes = INCLUDES,
    textual_hdrs = [
        "lib/lib.h",
        "lib/portability.h",
    ],
)

cc_library(
    name = "toybox_toys_lib",
    srcs = [
        "generated/tags.h",
    ] + glob([
        "toys/lsb/*.c",
        "toys/net/*.c",
        "toys/other/*.c",
        "toys/posix/*.c",
    ], exclude=["toys/lsb/passwd.c", "toys/other/chcon.c",],),
    copts = COPTS,
    #includes = INCLUDES,
    alwayslink = 1,
    textual_hdrs = [
        "toys.h",
    ],
    linkopts = ["-lresolv",],
    deps = [
        ":toybox_helper_lib",
    ],
)

cc_binary(
    name = "toybox",
    srcs = ["main.c"],
    copts = COPTS,
    features = [
        "fully_static_link",  # link libc statically
        "static_pie",
    ],
    linkopts = [
        "-s",
        "-Wl,--no-export-dynamic",
        "-Wl,--gc-sections",
        "-Wl,--as-needed",
        "-lcrypt",
        "-lutil",
        "-lm",
    ],
    output_licenses = ["notice"],
    deps = [
        ":toybox_helper_lib",
        ":toybox_toys_lib",
    ],
)

