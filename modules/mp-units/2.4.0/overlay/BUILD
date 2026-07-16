load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test", "cc_binary")
load("@rules_license//rules:license.bzl", "license")

package(
    default_applicable_licenses = [":license"],
)

exports_files(["LICENSE"])

license(
    name = "license",
    package_name = "mp-units",
    license_kinds = ["@rules_license//licenses/spdx:MIT"],
    license_text = "LICENSE",
    package_url = "https://github.com/mpusz/mp-units",
)

cc_library(
    name = "core",
    hdrs = glob(["src/core/include/**/*.h"]),
    defines = [
        "MP_UNITS_API_STD_FORMAT=1",
        "MP_UNITS_API_CONTRACTS=3", # MS-GSL
        "MP_UNITS_HOSTED=1",
    ],
    deps = ["@gsl//:gsl"],
    strip_include_prefix = "src/core/include",
    includes = ["src/core/include"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "systems",
    hdrs = glob(["src/systems/include/**/*.h"]),
    deps = [":core", "@gsl//:gsl"],
    strip_include_prefix = "src/systems/include",
    includes = ["src/systems/include"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "mp-units",
    deps = [
        ":core",
        ":systems",
    ],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "unit_tests_static",
    testonly = True,
    srcs = glob(["test/static/*.cpp"], exclude = [
                 "test/static/unit_magnitude_test.cpp",
                 "test/static/magnitude_test.cpp",
                 "test/static/custom_rep_test_min_expl.cpp",
                 "test/static/iau_test.cpp",
                ]) + ["test/static/test_tools.h"],
    deps = [
        "@mp-units",
    ],
)

cc_test(
    name = "unit_tests_runtime",
    srcs = glob(["test/runtime/*.cpp"],exclude = [
                 "test/runtime/linear_algebra_test.cpp",
                ]) + ["test/runtime/almost_equals.h"],
    deps = [
        "@mp-units",
        "@catch2//:catch2",
        "@catch2//:catch2_main",
    ],
    copts = ["-Wno-conversion", "-Wno-subobject-linkage",],
)

cc_binary(
    name = "hello_units",
    srcs = ["example/hello_units.cpp"],
    deps = [
        "@mp-units",
    ],
)
