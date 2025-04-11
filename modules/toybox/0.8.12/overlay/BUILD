load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_license//rules:license.bzl", "license")

package(
    default_applicable_licenses = [":license"],
    default_visibility = ["//visibility:public"],
)

license(
    name = "license",
    package_name = "toybox",
    license_kinds = ["@rules_license//licenses/spdx:0BSD"],
    license_text = "LICENSE",
    package_url = "https://github.com/landley/toybox",
)

COPTS = [
    "-I.",
    "-funsigned-char",
    "-w",
    "-Wundef",
    "-Wno-char-subscripts",
    "-Os",
    "-ffunction-sections",
    "-fdata-sections",
    "-fno-asynchronous-unwind-tables",
    "-fvisibility=hidden",
]

cc_library(
    name = "helper_lib",
    srcs = glob([
        # Headers generated following: https://github.com/landley/toybox/blob/master/README
        # make defconfig
        # make
        "generated/*.h",
        "lib/*.c",
        "lib/*.h",
    ]) + [
        "toys.h",
    ],
    copts = COPTS,
    features = [
        "-parse_headers",
    ],
    textual_hdrs = [
        "lib/lib.h",
        "lib/portability.h",
    ],
    visibility = ["//visibility:private"],
)

cc_library(
    name = "toys_lib",
    srcs = [
        "generated/tags.h",
    ] + glob(
        [
            "toys/lsb/*.c",
            "toys/net/*.c",
            "toys/other/*.c",
            "toys/posix/*.c",
        ],
        exclude = [
            "toys/lsb/passwd.c",
            "toys/other/chcon.c",
        ],
    ),
    copts = COPTS,
    linkopts = ["-lresolv"],
    textual_hdrs = [
        "toys.h",
    ],
    visibility = ["//visibility:private"],
    deps = [
        ":helper_lib",
    ],
)

cc_binary(
    name = "toybox",
    srcs = ["main.c"],
    copts = COPTS,
    features = [
        "fully_static_link",
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
    deps = [
        ":helper_lib",
        ":toys_lib",
    ],
)
