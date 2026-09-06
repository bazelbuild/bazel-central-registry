load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@cmake_configure_file//:cmake_configure_file.bzl", "cmake_configure_file")
load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test")
load("@rules_license//rules:license.bzl", "license")
load(":utils.bzl", "openusd_package_srcs", "package_local_defines")

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
    license_kinds = [],
    license_text = ":LICENSE.txt",
)

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

COMMON_CONLYOPTS = PLATFORM_COPTS

COMMON_CXXOPTS = ["-std=c++17"] + PLATFORM_COPTS

COMMON_LINKOPTS = select({
    "@platforms//os:windows": [],
    "//conditions:default": ["-lm"],
})

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

OPENUSD_PACKAGE_DIRS = {
    "ar": "pxr/usd/ar",
    "arch": "pxr/base/arch",
    "ef": "pxr/exec/ef",
    "esf": "pxr/exec/esf",
    "esfUsd": "pxr/exec/esfUsd",
    "exec": "pxr/exec/exec",
    "execGeom": "pxr/exec/execGeom",
    "execUsd": "pxr/exec/execUsd",
    "gf": "pxr/base/gf",
    "js": "pxr/base/js",
    "kind": "pxr/usd/kind",
    "pcp": "pxr/usd/pcp",
    "pegtl": "pxr/base/pegtl",
    "plug": "pxr/base/plug",
    "sdf": "pxr/usd/sdf",
    "sdr": "pxr/usd/sdr",
    "tf": "pxr/base/tf",
    "trace": "pxr/base/trace",
    "ts": "pxr/base/ts",
    "usd": "pxr/usd/usd",
    "usdGeom": "pxr/usd/usdGeom",
    "usdHydra": "pxr/usd/usdHydra",
    "usdLux": "pxr/usd/usdLux",
    "usdMedia": "pxr/usd/usdMedia",
    "usdPhysics": "pxr/usd/usdPhysics",
    "usdProc": "pxr/usd/usdProc",
    "usdRender": "pxr/usd/usdRender",
    "usdRi": "pxr/usd/usdRi",
    "usdSemantics": "pxr/usd/usdSemantics",
    "usdShade": "pxr/usd/usdShade",
    "usdShaders": "pxr/usd/plugin/usdShaders",
    "usdSkel": "pxr/usd/usdSkel",
    "usdUI": "pxr/usd/usdUI",
    "usdUtils": "pxr/usd/usdUtils",
    "usdVol": "pxr/usd/usdVol",
    "vdf": "pxr/exec/vdf",
    "vt": "pxr/base/vt",
    "work": "pxr/base/work",
}

OPENUSD_PACKAGE_EXTRA_PATTERNS = {
    "tf": [
        "pxr/base/tf/pxrDoubleConversion/*.cc",
        "pxr/base/tf/pxrLZ4/*.cpp",
    ],
    "work": ["pxr/base/work/workTBB/*.cpp"],
}

OPENUSD_PACKAGE_EXTRA_EXCLUDES = {
    "gf": ["pxr/base/gf/*.template.cpp"],
    "tf": [
        "pxr/base/tf/makePyConstructor.cpp",
        "pxr/base/tf/scriptModuleLoader.cpp",
    ],
    "ts": ["pxr/base/ts/tsTest_*.cpp"],
    "usd": ["pxr/usd/usd/examples_*.cpp"],
    "usdGeom": ["pxr/usd/usdGeom/examples_*.cpp"],
    "vt": [
        "pxr/base/vt/arrayPyBuffer.cpp",
        "pxr/base/vt/valueFromPython.cpp",
    ],
}

OPENUSD_PACKAGE_EXTRA_SRCS = {
    "gf": ["pxr/base/gf/nc/nanocolor.c"],
    "tf": [
        "pxr/base/tf/pyLock.cpp",
        "pxr/base/tf/pyObjWrapper.cpp",
        "pxr/base/tf/pyTracing.cpp",
    ],
}

UPSTREAM_VERSION = module_version().split(".bcr.", 1)[0]

UPSTREAM_VERSION_MAJOR = UPSTREAM_VERSION.split(".")[0]

UPSTREAM_VERSION_MINOR = UPSTREAM_VERSION.split(".")[1]

UPSTREAM_VERSION_MINOR_2DIGIT = "0" + UPSTREAM_VERSION_MINOR if len(UPSTREAM_VERSION_MINOR) == 1 else UPSTREAM_VERSION_MINOR

cmake_configure_file(
    name = "pxr_h",
    src = "pxr/pxr.h.in",
    out = "include/pxr/pxr.h",
    defines = [
        "PXR_MAJOR_VERSION=0",
        "PXR_MINOR_VERSION={}".format(UPSTREAM_VERSION_MAJOR),
        "PXR_PATCH_VERSION={}".format(UPSTREAM_VERSION_MINOR),
        "PXR_EXTERNAL_NAMESPACE=pxr",
        "PXR_INTERNAL_NAMESPACE=pxrInternal_v0_{}_{}".format(UPSTREAM_VERSION_MAJOR, UPSTREAM_VERSION_MINOR),
        "PXR_PREFER_SAFETY_OVER_SPEED=1",
        "PXR_PYTHON_SUPPORT_ENABLED=0",
        "PXR_USE_NAMESPACES=1",
        "PXR_VERSION={}{}".format(UPSTREAM_VERSION_MAJOR, UPSTREAM_VERSION_MINOR_2DIGIT),
    ],
)

cmake_configure_file(
    name = "impl_h",
    src = "pxr/base/work/impl.h.in",
    out = "include/pxr/base/work/impl.h",
    defines = [
        "PXR_WORK_IMPL_HEADER=\"pxr/base/work/workTBB/impl.h\"",
    ],
)

cc_library(
    name = "headers",
    hdrs = [
        ":impl_h",
        ":pxr_h",
    ],
    includes = ["include"],
)

cc_library(
    name = "pxr_headers",
    hdrs = glob([
        "pxr/**/*.h",
        "pxr/**/*.hpp",
    ]),
    include_prefix = "pxr",
    includes = ["pxr"],
    strip_include_prefix = "pxr",
)

[
    cc_library(
        name = package + "_pkg",
        srcs = openusd_package_srcs(
            package,
            OPENUSD_PACKAGE_DIRS,
            OPENUSD_PACKAGE_EXTRA_PATTERNS,
            OPENUSD_PACKAGE_EXTRA_EXCLUDES,
            OPENUSD_PACKAGE_EXTRA_SRCS,
        ),
        conlyopts = COMMON_CONLYOPTS,
        cxxopts = COMMON_CXXOPTS,
        local_defines = package_local_defines(package, COMMON_LOCAL_DEFINES),
        deps = [
            ":headers",
            ":pxr_headers",
            "@onetbb//:tbb",
        ],
        alwayslink = True,
    )
    for package in OPENUSD_PACKAGES
]

cc_library(
    name = "openusd",
    linkopts = COMMON_LINKOPTS,
    deps = [":" + package + "_pkg" for package in OPENUSD_PACKAGES],
    alwayslink = True,
)

# Maps plugin name to source directory for plugins with plugInfo.json
PLUGIN_DIRS = {
    "ar": "pxr/usd/ar",
    "esf": "pxr/exec/esf",
    "esfUsd": "pxr/exec/esfUsd",
    "exec": "pxr/exec/exec",
    "execGeom": "pxr/exec/execGeom",
    "execUsd": "pxr/exec/execUsd",
    "sdf": "pxr/usd/sdf",
    "sdr": "pxr/usd/sdr",
    "usd": "pxr/usd/usd",
    "usdGeom": "pxr/usd/usdGeom",
    "usdHydra": "pxr/usd/usdHydra",
    "usdLux": "pxr/usd/usdLux",
    "usdMedia": "pxr/usd/usdMedia",
    "usdPhysics": "pxr/usd/usdPhysics",
    "usdProc": "pxr/usd/usdProc",
    "usdRender": "pxr/usd/usdRender",
    "usdRi": "pxr/usd/usdRi",
    "usdSemantics": "pxr/usd/usdSemantics",
    "usdShade": "pxr/usd/usdShade",
    "usdSkel": "pxr/usd/usdSkel",
    "usdUI": "pxr/usd/usdUI",
    "usdVol": "pxr/usd/usdVol",
}

# Plugins that have generatedSchema.usda and schema.usda
SCHEMA_PLUGINS = [
    "usd",
    "usdGeom",
    "usdHydra",
    "usdLux",
    "usdMedia",
    "usdPhysics",
    "usdProc",
    "usdRender",
    "usdRi",
    "usdSemantics",
    "usdShade",
    "usdSkel",
    "usdUI",
    "usdVol",
]

PLUG_INFO_DEFINES = [
    "PLUG_INFO_LIBRARY_PATH=",
    "PLUG_INFO_RESOURCE_PATH=resources",
    "PLUG_INFO_ROOT=..",
]

# Generate plugInfo.json from upstream templates by substituting @PLUG_INFO_*@ variables
[cmake_configure_file(
    name = plugin + "_pluginfo",
    src = PLUGIN_DIRS[plugin] + "/plugInfo.json",
    out = "pluginfo/" + plugin + "/resources/plugInfo.json",
    defines = PLUG_INFO_DEFINES,
) for plugin in PLUGIN_DIRS]

# Root plugInfo.json that includes all plugin resources
genrule(
    name = "root_pluginfo",
    outs = ["pluginfo/plugInfo.json"],
    cmd = """echo '{"Includes":["*/resources/"]}' > $@""",
)

# Copy generatedSchema.usda from source tree
[copy_file(
    name = plugin + "_generated_schema",
    src = PLUGIN_DIRS[plugin] + "/generatedSchema.usda",
    out = "pluginfo/" + plugin + "/resources/generatedSchema.usda",
) for plugin in SCHEMA_PLUGINS]

# Copy schema.usda from source tree
[copy_file(
    name = plugin + "_schema",
    src = PLUGIN_DIRS[plugin] + "/schema.usda",
    out = "pluginfo/" + plugin + "/resources/" + plugin + "/schema.usda",
) for plugin in SCHEMA_PLUGINS]

# Copy usdHydra shader resources
copy_file(
    name = "usdHydra_shader_defs",
    src = "pxr/usd/usdHydra/shaders/shaderDefs.usda",
    out = "pluginfo/usdHydra/resources/shaders/shaderDefs.usda",
)

copy_file(
    name = "usdHydra_empty_glslfx",
    src = "pxr/usd/usdHydra/shaders/empty.glslfx",
    out = "pluginfo/usdHydra/resources/shaders/empty.glslfx",
)

# Assemble all plugin resources into the final directory structure
copy_to_directory(
    name = "plugin_files",
    srcs = [
        ":root_pluginfo",
        ":usdHydra_empty_glslfx",
        ":usdHydra_shader_defs",
    ] + [
        ":" + plugin + "_pluginfo"
        for plugin in PLUGIN_DIRS
    ] + [
        ":" + plugin + "_generated_schema"
        for plugin in SCHEMA_PLUGINS
    ] + [
        ":" + plugin + "_schema"
        for plugin in SCHEMA_PLUGINS
    ],
    out = "usd",
    replace_prefixes = {
        "pluginfo/": "",
    },
)

cc_test(
    name = "test_main",
    srcs = ["test_main.cpp"],
    data = [":plugin_files"],
    deps = [
        ":openusd",
        "@rules_cc//cc/runfiles",
    ],
)
