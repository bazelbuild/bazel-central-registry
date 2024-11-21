PLATFORM_LOCAL_DEFINES = select({
    "@platforms//os:windows": [
        "PLATFORM_CONFIG_H=\\\"libarchive_bazel_windows_config.h\\\"",
    ],
    "//conditions:default": [
        "PLATFORM_CONFIG_H=\\\"libarchive_bazel_generic_config.h\\\"",
    ],
})
