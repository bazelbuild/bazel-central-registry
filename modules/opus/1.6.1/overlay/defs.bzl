OPUS_COPTS = select({
    "@platforms//os:windows": [],
    "//conditions:default": ["-std=gnu99"],
})

OPUS_INCLUDES = [
    "include",
    "src",
    "celt",
    "silk",
    "silk/fixed",
    "silk/float",
    "celt/x86",
    "celt/arm",
    "silk/x86",
    "silk/arm",
    "dnn",
    "dnn/arm",
    "dnn/x86",
]

OPUS_LINKOPTS = select({
    "@platforms//os:windows": [],
    "//conditions:default": ["-lm"],
})

SSE_COPTS = select({
    "@platforms//os:windows": [],
    "//conditions:default": ["-msse"],
})
SSE2_COPTS = select({
    "@platforms//os:windows": [],
    "//conditions:default": ["-msse2"],
})
SSE4_1_COPTS = select({
    "@platforms//os:windows": [],
    "//conditions:default": ["-msse4.1"],
})
AVX2_COPTS = select({
    "@platforms//os:windows": ["/arch:AVX2"],
    "//conditions:default": ["-mavx", "-mfma", "-mavx2"],
})
