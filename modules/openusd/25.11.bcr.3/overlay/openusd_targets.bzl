load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test")
load(":openusd_srcs.bzl", "OPENUSD_PACKAGE_SRCS")

COMMON_LOCAL_DEFINES = [
    "BOOST_NO_CXX98_FUNCTION_BASE",
    "GLX_GLXEXT_PROTOTYPES",
    "GL_GLEXT_PROTOTYPES",
    "PXR_BUILD_LOCATION=usd",
    "PXR_PLUGIN_BUILD_LOCATION=../plugin/usd",
]

PLATFORM_COPTS = select({
    "@platforms//os:windows": [],
    "@platforms//os:macos": [
        "-faligned-allocation",
        "-ffp-contract=off",
        "-Wno-deprecated",
        "-Wno-deprecated-declarations",
        "-Wno-unused-local-typedefs",
        "-Wno-unused-command-line-argument",
        "-Wno-error",
    ],
    "//conditions:default": [
        "-ffp-contract=off",
        "-Wno-deprecated",
        "-Wno-deprecated-declarations",
        "-Wno-unused-local-typedefs",
        "-Wno-unused-command-line-argument",
        "-Wno-error",
    ],
})

COMMON_COPTS = ["-std=c++17"] + PLATFORM_COPTS

COMMON_LINKOPTS = select({
    "@platforms//os:windows": [],
    "//conditions:default": ["-lm"],
})

GF_NANOCOLOR_SRC = "pxr/base/gf/nc/nanocolor.c"

OPENUSD_PACKAGES = [
    "arch",
    "tf",
    "gf",
    "pegtl",
    "js",
    "trace",
    "work",
    "plug",
    "vt",
    "ts",
    "ar",
    "kind",
    "sdf",
    "sdr",
    "pcp",
    "usd",
    "usdGeom",
    "usdVol",
    "usdMedia",
    "usdShade",
    "usdLux",
    "usdProc",
    "usdRender",
    "usdHydra",
    "usdRi",
    "usdSemantics",
    "usdSkel",
    "usdUI",
    "usdUtils",
    "usdPhysics",
    "usdShaders",
    "vdf",
    "ef",
    "esf",
    "esfUsd",
    "exec",
    "execUsd",
    "execGeom",
]

def _package_module_name(package):
    return package[:1].upper() + package[1:]

def _package_local_defines(package):
    return COMMON_LOCAL_DEFINES + [
        package.upper() + "_EXPORTS=1",
        "MFB_ALT_PACKAGE_NAME=" + package,
        "MFB_PACKAGE_MODULE=" + _package_module_name(package),
        "MFB_PACKAGE_NAME=" + package,
    ]

def define_openusd_targets():
    cc_library(
        name = "headers",
        hdrs = [
            "include/pxr/pxr.h",
            "include/pxr/base/work/impl.h",
        ],
        includes = ["include"],
    )

    cc_library(
        name = "pxr_headers",
        hdrs = native.glob([
            "pxr/**/*.h",
            "pxr/**/*.hpp",
        ]),
        strip_include_prefix = "pxr",
        include_prefix = "pxr",
        includes = ["pxr"],
    )

    cc_library(
        name = "gf_nanocolor",
        srcs = [GF_NANOCOLOR_SRC],
        copts = PLATFORM_COPTS,
        local_defines = _package_local_defines("gf"),
        deps = [
            ":headers",
            ":pxr_headers",
        ],
    )

    for package in OPENUSD_PACKAGES:
        cc_library(
            name = package + "_pkg",
            srcs = [src for src in OPENUSD_PACKAGE_SRCS[package] if src != GF_NANOCOLOR_SRC],
            copts = COMMON_COPTS,
            local_defines = _package_local_defines(package),
            deps = [
                ":headers",
                ":pxr_headers",
                "@onetbb//:tbb",
            ] + ([
                ":gf_nanocolor",
            ] if package == "gf" else []),
            alwayslink = True,
        )

    cc_library(
        name = "openusd",
        deps = [
            ":arch_pkg",
            ":tf_pkg",
            ":gf_pkg",
            ":pegtl_pkg",
            ":js_pkg",
            ":trace_pkg",
            ":work_pkg",
            ":plug_pkg",
            ":vt_pkg",
            ":ts_pkg",
            ":ar_pkg",
            ":kind_pkg",
            ":sdf_pkg",
            ":sdr_pkg",
            ":pcp_pkg",
            ":usd_pkg",
            ":usdGeom_pkg",
            ":usdVol_pkg",
            ":usdMedia_pkg",
            ":usdShade_pkg",
            ":usdLux_pkg",
            ":usdProc_pkg",
            ":usdRender_pkg",
            ":usdHydra_pkg",
            ":usdRi_pkg",
            ":usdSemantics_pkg",
            ":usdSkel_pkg",
            ":usdUI_pkg",
            ":usdUtils_pkg",
            ":usdPhysics_pkg",
            ":usdShaders_pkg",
            ":vdf_pkg",
            ":ef_pkg",
            ":esf_pkg",
            ":esfUsd_pkg",
            ":exec_pkg",
            ":execUsd_pkg",
            ":execGeom_pkg",
        ],
        alwayslink = True,
        linkopts = COMMON_LINKOPTS,
    )

    native.filegroup(
        name = "plugin_resource_files",
        srcs = native.glob(["plugin_resources/**"], allow_empty = False),
    )

    copy_to_directory(
        name = "plugin_files",
        srcs = [":plugin_resource_files"],
        out = "usd",
        replace_prefixes = {
            "plugin_resources": "",
        },
    )

    cc_test(
        name = "test_main",
        srcs = ["test_main.cpp"],
        deps = [
            ":openusd",
            "@rules_cc//cc/runfiles",
        ],
        data = [":plugin_files"],
    )
