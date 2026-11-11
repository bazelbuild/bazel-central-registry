load("@bazel_skylib//lib:selects.bzl", "selects")
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_java//java:defs.bzl", "java_binary")
load("@rules_jni//jni:defs.bzl", "cc_jni_library", "java_jni_library")

def ultrahdr_targets():
    native.exports_files([
        "heif.BUILD.bazel",
        "smpte.BUILD.bazel",
        "deps/heif_gainmap.patch",
        "deps/smpte_cxx_bridge.patch",
        "build_defs.bzl",
    ])

    for setting, default in [
        ("enable_heif", True),
        ("enable_intrinsics", True),
        ("enable_logs", False),
        ("enable_smpte2094_50", False),
        ("write_iso", True),
        ("write_xmp", False),
    ]:
        bool_flag(name = setting, build_setting_default = default, visibility = ["//visibility:public"])
        native.config_setting(name = "_" + setting, flag_values = {":" + setting: "True"})

    selects.config_setting_group(
        name = "_arm",
        match_any = [
            "@platforms//cpu:aarch64",
            "@platforms//cpu:armv7",
        ],
    )

    selects.config_setting_group(
        name = "_neon",
        match_all = [
            ":_arm",
            ":_enable_intrinsics",
        ],
    )

    selects.config_setting_group(
        name = "_gcc_or_clang",
        match_any = ["@rules_cc//cc/compiler:gcc", "@rules_cc//cc/compiler:clang"],
    )

    selects.config_setting_group(
        name = "_gnu_armv7",
        match_all = [
            "@platforms//cpu:armv7",
            ":_enable_intrinsics",
            ":_gcc_or_clang",
        ],
    )

    selects.config_setting_group(
        name = "_write_metadata",
        match_any = [":_write_iso", ":_write_xmp"],
    )

    _CXX_COPTS = select({
        "@rules_cc//cc/compiler:msvc-cl": ["/std:c++17"],
        "//conditions:default": ["-std=c++17"],
    }) + select({
        ":_gnu_armv7": ["-mfpu=neon"],
        "//conditions:default": [],
    })

    cc_library(
        name = "image_io",
        srcs = native.glob(["third_party/image_io/src/**/*.cc"]),
        hdrs = native.glob([
            "third_party/image_io/includes/**/*.h",
            "third_party/image_io/src/**/*.h",
        ]),
        copts = _CXX_COPTS,
        includes = [
            "third_party/image_io/includes",
            "third_party/image_io/src/modp_b64",
            "third_party/image_io/src/modp_b64/modp_b64",
        ],
    )

    _SRCS = native.glob(["lib/src/*.cpp"]) + select({
        ":_neon": native.glob(["lib/src/dsp/arm/*.cpp"]),
        "//conditions:default": [],
    })

    _DEFINES = select({
        ":_enable_heif": ["UHDR_ENABLE_HEIF"],
        "//conditions:default": [],
    }) + select({
        ":_enable_intrinsics": ["UHDR_ENABLE_INTRINSICS"],
        "//conditions:default": [],
    }) + select({
        ":_enable_smpte2094_50": ["UHDR_ENABLE_SMPTE2094_50"],
        "//conditions:default": [],
    }) + select({
        ":_write_iso": ["UHDR_WRITE_ISO"],
        "//conditions:default": [],
    }) + select({
        ":_write_xmp": ["UHDR_WRITE_XMP"],
        "//conditions:default": [],
    }) + select({
        ":_enable_logs": ["LOG_NDEBUG"],
        "//conditions:default": [],
    })

    _DEPS = [
        ":image_io",
        "@libjpeg_turbo//:jpeg",
    ] + select({
        ":_enable_heif": ["@ultrahdr_heif//:heif"],
        "//conditions:default": [],
    }) + select({
        ":_enable_smpte2094_50": ["@ultrahdr_smpte//:smpte2094_50_utils"],
        "//conditions:default": [],
    })

    _ATTRS = {
        "hdrs": ["ultrahdr_api.h"] + native.glob(["lib/include/**/*.h"]),
        "copts": _CXX_COPTS + select(
            {":_write_metadata": []},
            no_match_error = "Enable write_iso or write_xmp, as required by upstream.",
        ),
        "includes": [
            ".",
            "lib/include",
        ],
        "linkopts": select({
            "@platforms//os:windows": [],
            "//conditions:default": ["-pthread"],
        }),
        "visibility": ["//visibility:public"],
    }

    cc_library(
        name = "ultrahdr",
        srcs = _SRCS,
        defines = _DEFINES,
        deps = _DEPS,
        **_ATTRS
    )

    native.alias(
        name = "libultrahdr",
        actual = ":ultrahdr",
        visibility = ["//visibility:public"],
    )

    native.alias(
        name = "smpte2094_50",
        actual = "@ultrahdr_smpte//:smpte2094_50_utils",
        visibility = ["//visibility:public"],
    )

    native.label_flag(
        name = "gles_backend",
        build_setting_default = ":system_gles",
        visibility = ["//visibility:public"],
    )

    cc_library(
        name = "system_gles",
        linkopts = select({
            "@platforms//os:windows": [
                "EGL.lib",
                "GLESv2.lib",
            ],
            "//conditions:default": [
                "-lEGL",
                "-lGLESv2",
            ],
        }),
    )

    cc_library(
        name = "gles",
        deps = [
            ":gles_backend",
            "@egl-registry//:EGL_headers",
            "@opengl-registry//:GLES3_headers",
        ],
    )

    cc_library(
        name = "ultrahdr_gpu",
        srcs = _SRCS + native.glob(["lib/src/gpu/*.cpp"]),
        defines = _DEFINES + ["UHDR_ENABLE_GLES"],
        deps = _DEPS + [":gles"],
        **_ATTRS
    )

    cc_binary(
        name = "ultrahdr_app",
        srcs = ["examples/ultrahdr_app.cpp"],
        copts = _CXX_COPTS,
        visibility = ["//visibility:public"],
        deps = [":ultrahdr"],
    )

    cc_binary(
        name = "ultrahdr_gpu_app",
        srcs = ["examples/ultrahdr_app.cpp"],
        copts = _CXX_COPTS,
        visibility = ["//visibility:public"],
        deps = [":ultrahdr_gpu"],
    )

    cc_jni_library(
        name = "uhdrjni",
        srcs = native.glob([
            "java/jni/*.cpp",
            "java/jni/*.h",
        ]),
        copts = _CXX_COPTS,
        visibility = ["//visibility:public"],
        deps = [":ultrahdr"],
    )

    java_jni_library(
        name = "java",
        srcs = native.glob(["java/com/google/media/codecs/ultrahdr/*.java"]),
        native_libs = [":uhdrjni"],
        visibility = ["//visibility:public"],
    )

    java_binary(
        name = "ultrahdr_java_app",
        srcs = ["java/UltraHdrApp.java"],
        main_class = "UltraHdrApp",
        visibility = ["//visibility:public"],
        deps = [":java"],
    )
