OPUS_COPTS = ["-std=gnu99"]

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

OPUS_LINKOPTS = ["-lm"]

SSE_COPTS = ["-msse"]
SSE2_COPTS = ["-msse2"]
SSE4_1_COPTS = ["-msse4.1"]
AVX2_COPTS = ["-mavx", "-mfma", "-mavx2"]
