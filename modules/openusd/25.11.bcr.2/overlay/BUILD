load("@rules_foreign_cc//foreign_cc:defs.bzl", "cmake")
load("@rules_cc//cc:defs.bzl", "cc_test")
load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_license//rules:license.bzl", "license")
load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")

package(
    default_applicable_licenses = [":license"],
    default_visibility = ["//visibility:public"],
)

exports_files(["LICENSE.txt"])

# Note: OpenUSD uses a derivative of the Apache 2.0 license called the
# Tomorrow Open Source Technology License 1.0.
license(
    name = "license",
    package_name = "openusd",
    license_kinds = [
    ],
    license_text = ":LICENSE.txt",
)

filegroup(
    name = "all_srcs",
    srcs = glob([
    	"CMakeLists.txt",
    	"pxr/**",
    	"cmake/**",
    	"extras/**",
    	"docs/**",
    	"third_party/**"
    ], exclude=[
    	"bazel*/**",
    	"BUILD",
    	"BUILD.bazel",
    	"MODULE.bazel"
    ]),
    visibility = ["//visibility:public"],
)

# Build OpenUSD as a monolithic static library. This is the simplest option for linking
# but note it does not allow USD plugins or Python modules. This is because it  would result in duplicate
# symbol definitions for libusd symbols (statically linked into the main exec and also linked into the dynamic libs).
#
# Also note: We must specify the alwayslink=True so that dependents link in all symbols from the archive. This is
# a stated requirement in BUILDING.md. If not specified, OpenUSD will not initialize properly and you will encounter
# segfaults when using certain objects.
#
# See BUILDING.md in the OpenUSD repo for details.
#
cmake(
    name = "openusd",
    cache_entries = {
        "BUILD_SHARED_LIBS": "OFF",
        "PXR_BUILD_MONOLITHIC": "ON",
        "PXR_PREFER_SAFETY_OVER_SPEED": "ON",
        "PXR_FIND_TBB_IN_CONFIG": "OFF",
        "TBB_USE_DEBUG_BUILD": "OFF",
        "PXR_ENABLE_PYTHON_SUPPORT": "OFF",
        "PXR_ENABLE_GL_SUPPORT": "OFF",
        "PXR_ENABLE_METAL_SUPPORT": "OFF",
        "PXR_BUILD_DOCUMENTATION": "OFF",
        "PXR_BUILD_HTML_DOCUMENTATION": "OFF",
        "PXR_BUILD_PYTHON_DOCUMENTATION": "OFF",
        "PXR_BUILD_TESTS": "OFF",
        "PXR_BUILD_EXAMPLES": "OFF",
        "PXR_BUILD_TUTORIALS": "OFF",
        "PXR_BUILD_USD_TOOLS": "OFF",
        "PXR_BUILD_USD_VALIDATION": "OFF",
        "PXR_BUILD_IMAGING": "OFF",
        "PXR_BUILD_USD_IMAGING": "OFF",
        "PXR_BUILD_USDVIEW": "OFF",
        "PXR_BUILD_ALEMBIC_PLUGIN": "OFF",
        "PXR_BUILD_DRACO_PLUGIN": "OFF",
        "PXR_ENABLE_MATERIALX_SUPPORT": "OFF",
        "PXR_BUILD_MAYAPY_TESTS": "OFF",
        "PXR_BUILD_ANIMX_TESTS": "OFF",
        "Boost_NO_SYSTEM_PATHS": "ON",
    },
    env = {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_BUILD_PARALLEL_LEVEL": "4",
    },
    # OpenUSD generates many compiler warnings. It will fail
    # to compile if these warnings are treated as errors.
    copts = [
        "-Wno-error",
    ],
    alwayslink = True,
    out_static_libs = [
        # This is name of the monolithic static lib.
	    "libusd_m.a",
    ],
    out_data_dirs = [
	    "lib/usd"
    ],
    lib_source = ":all_srcs",
    deps = [
        "@onetbb//:tbb",
    ],
)

# As part of the cmake build, OpenUSD installs a directory of plugin file resources (many plugInfo.json files)
# to openusd/lib/usd. On program startup, OpenUSD expects these plugin files to be in a usd/ dir directly next
# to the executable or .so library. It will throw an exception and crash if they are not found.
# We use the 'copy_to_directory' helper to copy them out of 'openusd/lib/usd' to just 'usd' so that they
# are at the right path.
copy_to_directory(
    name = "plugin_files",
    srcs = [":openusd"],
    out = "usd",
    replace_prefixes = {
        "openusd/lib/usd": "",
    }
)

cc_test(
    name = "test_main",
    srcs = ["test_main.cpp"],
    deps = [
      ":openusd",
      "@bazel_tools//tools/cpp/runfiles",
    ],
    data = [
	    ":plugin_files",
    ]
)

