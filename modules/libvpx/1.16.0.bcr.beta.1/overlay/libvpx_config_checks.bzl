"""rules_cc_autoconf checks for libvpx config generation."""

load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")

_UNQUOTED_DEFINES = [
    ("RESTRICT", ""),
    ("INLINE", "inline"),
]

_FIXED_DEFINES = [
    ("VPX_ARCH_ARM", "0"),
    ("VPX_ARCH_AARCH64", "0"),
    ("VPX_ARCH_MIPS", "0"),
    ("VPX_ARCH_X86", "0"),
    ("VPX_ARCH_X86_64", "0"),
    ("VPX_ARCH_PPC", "0"),
    ("VPX_ARCH_LOONGARCH", "0"),
    ("HAVE_NEON_ASM", "0"),
    ("HAVE_NEON", "0"),
    ("HAVE_NEON_DOTPROD", "0"),
    ("HAVE_NEON_I8MM", "0"),
    ("HAVE_SVE", "0"),
    ("HAVE_SVE2", "0"),
    ("HAVE_MIPS32", "0"),
    ("HAVE_DSPR2", "0"),
    ("HAVE_MSA", "0"),
    ("HAVE_MIPS64", "0"),
    ("HAVE_MMX", "0"),
    ("HAVE_SSE", "0"),
    ("HAVE_SSE2", "0"),
    ("HAVE_SSE3", "0"),
    ("HAVE_SSSE3", "0"),
    ("HAVE_SSE4_1", "0"),
    ("HAVE_AVX", "0"),
    ("HAVE_AVX2", "0"),
    ("HAVE_AVX512", "0"),
    ("HAVE_VSX", "0"),
    ("HAVE_MMI", "0"),
    ("HAVE_LSX", "0"),
    ("HAVE_LASX", "0"),
    ("HAVE_VPX_PORTS", "1"),
    ("CONFIG_DEPENDENCY_TRACKING", "1"),
    ("CONFIG_EXTERNAL_BUILD", "0"),
    ("CONFIG_INSTALL_DOCS", "0"),
    ("CONFIG_INSTALL_BINS", "1"),
    ("CONFIG_INSTALL_LIBS", "1"),
    ("CONFIG_INSTALL_SRCS", "0"),
    ("CONFIG_DEBUG", "0"),
    ("CONFIG_GPROF", "0"),
    ("CONFIG_GCOV", "0"),
    ("CONFIG_RVCT", "0"),
    ("CONFIG_GCC", "1"),
    ("CONFIG_MSVS", "0"),
    ("CONFIG_PIC", "1"),
    ("CONFIG_BIG_ENDIAN", "0"),
    ("CONFIG_CODEC_SRCS", "0"),
    ("CONFIG_DEBUG_LIBS", "0"),
    ("CONFIG_DEQUANT_TOKENS", "0"),
    ("CONFIG_DC_RECON", "0"),
    ("CONFIG_RUNTIME_CPU_DETECT", "0"),
    ("CONFIG_POSTPROC", "0"),
    ("CONFIG_VP9_POSTPROC", "0"),
    ("CONFIG_MULTITHREAD", "1"),
    ("CONFIG_INTERNAL_STATS", "0"),
    ("CONFIG_VP8_ENCODER", "1"),
    ("CONFIG_VP8_DECODER", "1"),
    ("CONFIG_VP9_ENCODER", "1"),
    ("CONFIG_VP9_DECODER", "1"),
    ("CONFIG_VP8", "1"),
    ("CONFIG_VP9", "1"),
    ("CONFIG_ENCODERS", "1"),
    ("CONFIG_DECODERS", "1"),
    ("CONFIG_STATIC_MSVCRT", "0"),
    ("CONFIG_SPATIAL_RESAMPLING", "1"),
    ("CONFIG_REALTIME_ONLY", "0"),
    ("CONFIG_ONTHEFLY_BITPACKING", "0"),
    ("CONFIG_ERROR_CONCEALMENT", "0"),
    ("CONFIG_SHARED", "0"),
    ("CONFIG_STATIC", "1"),
    ("CONFIG_SMALL", "0"),
    ("CONFIG_POSTPROC_VISUALIZER", "0"),
    ("CONFIG_OS_SUPPORT", "1"),
    ("CONFIG_UNIT_TESTS", "0"),
    ("CONFIG_WEBM_IO", "1"),
    ("CONFIG_LIBYUV", "1"),
    ("CONFIG_DECODE_PERF_TESTS", "0"),
    ("CONFIG_ENCODE_PERF_TESTS", "0"),
    ("CONFIG_MULTI_RES_ENCODING", "0"),
    ("CONFIG_TEMPORAL_DENOISING", "1"),
    ("CONFIG_VP9_TEMPORAL_DENOISING", "0"),
    ("CONFIG_COEFFICIENT_RANGE_CHECKING", "0"),
    ("CONFIG_VP9_HIGHBITDEPTH", "0"),
    ("CONFIG_BETTER_HW_COMPATIBILITY", "0"),
    ("CONFIG_EXPERIMENTAL", "0"),
    ("CONFIG_SIZE_LIMIT", "0"),
    ("CONFIG_ALWAYS_ADJUST_BPM", "0"),
    ("CONFIG_BITSTREAM_DEBUG", "0"),
    ("CONFIG_MISMATCH_DEBUG", "0"),
    ("CONFIG_FP_MB_STATS", "0"),
    ("CONFIG_EMULATE_HARDWARE", "0"),
    ("CONFIG_NON_GREEDY_MV", "0"),
    ("CONFIG_COLLECT_COMPONENT_TIMING", "0"),
]

LIBVPX_CONFIG_CHECKS = (
    [
        checks.AC_DEFINE_UNQUOTED(name, value)
        for name, value in _UNQUOTED_DEFINES
    ] +
    [
        checks.AC_DEFINE(name, value)
        for name, value in _FIXED_DEFINES
    ] +
    [
        checks.AC_SUBST(name, "yes" if value == "1" else "no")
        for name, value in _FIXED_DEFINES
    ] +
    [
        checks.AC_CHECK_HEADER("pthread.h", define = "HAVE_PTHREAD_H"),
        checks.AC_CHECK_HEADER("unistd.h", define = "HAVE_UNISTD_H"),
        checks.AC_SUBST("HAVE_PTHREAD_H", condition = "ac_cv_header_pthread_h", if_true = "yes", if_false = "no"),
        checks.AC_SUBST("HAVE_UNISTD_H", condition = "ac_cv_header_unistd_h", if_true = "yes", if_false = "no"),
    ]
)
