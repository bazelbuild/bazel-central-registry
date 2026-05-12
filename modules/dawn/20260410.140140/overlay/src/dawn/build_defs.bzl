load("//src/tint:flags.bzl", "COPTS")

DAWN_COPTS = COPTS + select({
    "@platforms//os:android": [
        "-DDAWN_ENABLE_BACKEND_VULKAN",
    ],
    "@platforms//os:linux": [
        "-DDAWN_ENABLE_BACKEND_VULKAN",
    ],
    "@platforms//os:macos": [
        "-DDAWN_ENABLE_BACKEND_METAL",
    ],
    "@platforms//os:ios": [
        "-DDAWN_ENABLE_BACKEND_METAL",
    ],
    "@platforms//os:windows": [
        "-DDAWN_ENABLE_BACKEND_D3D12",
        "-DNTDDI_VERSION=0x0A000000",
        "-DWINVER=0x0A00",
        "-D_WIN32_WINNT=0x0A00",
    ],
    "//conditions:default": [],
}) + [
    "-Isrc",
]

DAWN_INTERNAL_INCLUDES = ["../.."]

DAWN_APPLE_COMMON_LINKOPTS = [
    "-framework",
    "CoreFoundation",
    "-framework",
    "CoreVideo",
    "-framework",
    "Foundation",
    "-framework",
    "IOSurface",
]

DAWN_ANDROID_COMMON_LINKOPTS = [
    "-llog",
]

DAWN_LINUX_COMMON_LINKOPTS = [
    "-ldl",
]

DAWN_APPLE_SYSTEM_UTILS_LINKOPTS = [
    "-framework",
    "CoreServices",
    "-framework",
    "QuartzCore",
]

DAWN_APPLE_METAL_LINKOPTS = [
    "-framework",
    "Cocoa",
    "-framework",
    "IOKit",
    "-framework",
    "IOSurface",
    "-framework",
    "Metal",
    "-framework",
    "QuartzCore",
]
