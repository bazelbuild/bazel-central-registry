"""Generated config macros for libaom 3.13.3.

Config values match cmake's generate_aom_config_templates.cmake with
platform-dependent arch/ISA values for x86_64 and aarch64.

Feature flag defines are driven by select() on the bool_flag targets
declared in BUILD.bazel.

## Updating to a new AOM release

1. Diff upstream build/cmake/aom_config_defaults.cmake against the
   previous version.  Each cmake `option()` or `set(... CACHE BOOL)`
   maps to one row in _FLAG_DEFINES below.

2. For simple on/off flags: add or remove a row in _FLAG_DEFINES and
   a matching bool_flag + config_setting pair in BUILD.bazel.

3. For coupled flags (one setting controls multiple defines, e.g.
   REALTIME_ONLY ↔ QUANT_MATRIX): add an inline select() in both
   aom_config_h() and aom_config_asm() with a comment explaining
   the coupling.

4. For new arch/ISA defines: update the _H_ARCH_*, _H_ISA_*, _ASM_ARCH,
   and _ASM_ISA_* string blocks.

5. For new platform-dependent defines: update _H_PLATFORM_* and
   _ASM_PLATFORM_* blocks.

6. For new always-fixed defines: add to _H_CONFIG_FIXED / _ASM_CONFIG_FIXED.

7. Update _AOM_VERSION_H_CONTENT with the new version numbers.
"""

load("@bazel_skylib//rules:write_file.bzl", "write_file")

# -- gen_config_file rule -------------------------------------------------

def _gen_config_file_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    ctx.actions.write(out, ctx.attr.content)
    return [
        DefaultInfo(files = depset([out])),
    ]

_gen_config_file = rule(
    implementation = _gen_config_file_impl,
    attrs = {
        "content": attr.string(mandatory = True),
        "out": attr.string(mandatory = True),
    },
)

# =========================================================================
# Flag-driven defines
# =========================================================================
#
# Mirrors build/cmake/aom_config_defaults.cmake.  Each entry maps a CMake
# variable name to the Bazel config_setting that enables it.  Both
# aom_config.h (#define) and aom_config.asm (NASM equ) are generated from
# this single table — add or remove a row when bumping AOM versions.
#
# Special cases that can NOT go in this table (coupled or compound
# conditions) are handled inline in aom_config_h / aom_config_asm below.

_FLAG_DEFINES = [
    ("CONFIG_ACCOUNTING", ":accounting_enabled"),
    ("CONFIG_AV1_DECODER", ":decoder_enabled"),
    ("CONFIG_AV1_ENCODER", ":encoder_enabled"),
    ("CONFIG_AV1_HIGHBITDEPTH", ":highbitdepth_enabled"),
    ("CONFIG_AV1_TEMPORAL_DENOISING", ":temporal_denoising_enabled"),
    ("CONFIG_BITSTREAM_DEBUG", ":bitstream_debug_enabled"),
    ("CONFIG_COEFFICIENT_RANGE_CHECKING", ":coefficient_range_checking_enabled"),
    ("CONFIG_COLLECT_COMPONENT_TIMING", ":collect_component_timing_enabled"),
    ("CONFIG_COLLECT_PARTITION_STATS", ":collect_partition_stats_enabled"),
    ("CONFIG_COLLECT_RD_STATS", ":collect_rd_stats_enabled"),
    ("CONFIG_CWG_C013", ":cwg_c013_enabled"),
    ("CONFIG_CWG_E050", ":cwg_e050_enabled"),
    ("CONFIG_DENOISE", ":denoise_enabled"),
    ("CONFIG_ENTROPY_STATS", ":entropy_stats_enabled"),
    ("CONFIG_FPMT_TEST", ":fpmt_test_enabled"),
    ("CONFIG_HIGHWAY", ":highway_enabled"),
    ("CONFIG_INSPECTION", ":inspection_enabled"),
    ("CONFIG_INTERNAL_STATS", ":internal_stats_enabled"),
    ("CONFIG_INTER_STATS_ONLY", ":inter_stats_only_enabled"),
    ("CONFIG_LIBYUV", ":libyuv_enabled"),
    ("CONFIG_MISMATCH_DEBUG", ":mismatch_debug_enabled"),
    ("CONFIG_MULTITHREAD", ":multithread_enabled"),
    ("CONFIG_NN_V2", ":nn_v2_enabled"),
    ("CONFIG_NORMAL_TILE_MODE", ":normal_tile_mode_enabled"),
    ("CONFIG_OPTICAL_FLOW_API", ":optical_flow_api_enabled"),
    ("CONFIG_OUTPUT_FRAME_SIZE", ":output_frame_size_enabled"),
    ("CONFIG_PARTITION_SEARCH_ORDER", ":partition_search_order_enabled"),
    ("CONFIG_RATECTRL_LOG", ":ratectrl_log_enabled"),
    ("CONFIG_RD_COMMAND", ":rd_command_enabled"),
    ("CONFIG_RD_DEBUG", ":rd_debug_enabled"),
    ("CONFIG_RT_ML_PARTITIONING", ":rt_ml_partitioning_enabled"),
    ("CONFIG_RUNTIME_CPU_DETECT", ":runtime_cpu_detect_enabled"),
    ("CONFIG_SALIENCY_MAP", ":saliency_map_enabled"),
    ("CONFIG_SIZE_LIMIT", ":size_limit_enabled"),
    ("CONFIG_SPEED_STATS", ":speed_stats_enabled"),
    ("CONFIG_TFLITE", ":tflite_enabled"),
    ("CONFIG_THREE_PASS", ":three_pass_enabled"),
    ("CONFIG_TUNE_BUTTERAUGLI", ":tune_butteraugli_enabled"),
    ("CONFIG_TUNE_VMAF", ":tune_vmaf_enabled"),
    ("CONFIG_WEBM_IO", ":webm_io_enabled"),
    ("FORCE_HIGHBITDEPTH_DECODING", ":force_highbitdepth_decoding_enabled"),
]

# -- Helpers ---------------------------------------------------------------

def _h_flags(flags):
    """Generate ``#define`` lines from the flag table."""
    content = ""
    for define, label in flags:
        content = content + select({
            label: "#define " + define + " 1\n",
            "//conditions:default": "#define " + define + " 0\n",
        })
    return content

def _asm_flags(flags):
    """Generate NASM ``equ`` lines from the flag table."""
    content = ""
    for define, label in flags:
        content = content + select({
            label: define + " equ 1\n",
            "//conditions:default": define + " equ 0\n",
        })
    return content

# =========================================================================
# aom_config.h content segments
# =========================================================================

_H_GUARD_OPEN = """\
#ifndef AOM_CONFIG_H_
#define AOM_CONFIG_H_
"""

_H_GUARD_CLOSE = "#endif  // AOM_CONFIG_H_\n"

_H_ARCH_X86_64 = """\
#define AOM_ARCH_AARCH64 0
#define AOM_ARCH_ARM 0
#define AOM_ARCH_PPC 0
#define AOM_ARCH_RISCV 0
#define AOM_ARCH_X86 0
#define AOM_ARCH_X86_64 1
"""

_H_ARCH_AARCH64 = """\
#define AOM_ARCH_AARCH64 1
#define AOM_ARCH_ARM 1
#define AOM_ARCH_PPC 0
#define AOM_ARCH_RISCV 0
#define AOM_ARCH_X86 0
#define AOM_ARCH_X86_64 0
"""

# -- Platform-dependent defines (Unix vs Windows) --------------------------

_H_PLATFORM_UNIX = """\
#define CONFIG_GCC 1
#define CONFIG_PIC 1
#define HAVE_FEXCEPT 1
#define HAVE_PTHREAD_H 1
#define HAVE_UNISTD_H 1
"""

_H_PLATFORM_WINDOWS = """\
#define CONFIG_GCC 0
#define CONFIG_PIC 0
#define HAVE_FEXCEPT 0
#define HAVE_PTHREAD_H 0
#define HAVE_UNISTD_H 0
"""

# -- Fixed defines (not controlled by any flag) ----------------------------

_H_CONFIG_FIXED = """\
#define CONFIG_ANALYZER 0
#define CONFIG_BIG_ENDIAN 0
#define CONFIG_BITRATE_ACCURACY 0
#define CONFIG_BITRATE_ACCURACY_BL 0
#define CONFIG_DEBUG 0
#define CONFIG_EXCLUDE_SIMD_MISMATCH 0
#define CONFIG_GCOV 0
#define CONFIG_GPROF 0
#define CONFIG_LIBVMAF_PSNR_PEAK 1
#define CONFIG_MAX_DECODE_PROFILE 2
#define CONFIG_OS_SUPPORT 1
#define CONFIG_SHARED 0
#define CONFIG_SVT_AV1 1
#define DECODE_HEIGHT_LIMIT 0
#define DECODE_WIDTH_LIMIT 0
#define HAVE_WXWIDGETS 0
#define STATIC_LINK_JXL 0
"""

# -- ISA capability defines ------------------------------------------------

_H_ISA_X86_64 = """\
#define HAVE_ARM_CRC32 0
#define HAVE_AVX 1
#define HAVE_AVX2 1
#define HAVE_AVX512 0
#define HAVE_MMX 1
#define HAVE_NEON 0
#define HAVE_NEON_DOTPROD 0
#define HAVE_NEON_I8MM 0
#define HAVE_RVV 0
#define HAVE_SSE 1
#define HAVE_SSE2 1
#define HAVE_SSE3 1
#define HAVE_SSE4_1 1
#define HAVE_SSE4_2 1
#define HAVE_SSSE3 1
#define HAVE_SVE 0
#define HAVE_SVE2 0
#define HAVE_VSX 0
"""

_H_ISA_AARCH64 = """\
#define HAVE_ARM_CRC32 1
#define HAVE_AVX 0
#define HAVE_AVX2 0
#define HAVE_AVX512 0
#define HAVE_MMX 0
#define HAVE_NEON 1
#define HAVE_NEON_DOTPROD 1
#define HAVE_NEON_I8MM 1
#define HAVE_RVV 0
#define HAVE_SSE 0
#define HAVE_SSE2 0
#define HAVE_SSE3 0
#define HAVE_SSE4_1 0
#define HAVE_SSE4_2 0
#define HAVE_SSSE3 0
#define HAVE_SVE 0
#define HAVE_SVE2 0
#define HAVE_VSX 0
"""

# =========================================================================
# aom_config.asm content segments (x86_64 NASM equ format)
# =========================================================================

_ASM_ARCH = """\
AOM_ARCH_AARCH64 equ 0
AOM_ARCH_ARM equ 0
AOM_ARCH_PPC equ 0
AOM_ARCH_RISCV equ 0
AOM_ARCH_X86 equ 0
AOM_ARCH_X86_64 equ 1
"""

_ASM_PLATFORM_UNIX = """\
CONFIG_GCC equ 1
CONFIG_PIC equ 1
HAVE_FEXCEPT equ 1
HAVE_PTHREAD_H equ 1
HAVE_UNISTD_H equ 1
"""

_ASM_PLATFORM_WINDOWS = """\
CONFIG_GCC equ 0
CONFIG_PIC equ 0
HAVE_FEXCEPT equ 0
HAVE_PTHREAD_H equ 0
HAVE_UNISTD_H equ 0
"""

_ASM_CONFIG_FIXED = """\
CONFIG_ANALYZER equ 0
CONFIG_BIG_ENDIAN equ 0
CONFIG_BITRATE_ACCURACY equ 0
CONFIG_BITRATE_ACCURACY_BL equ 0
CONFIG_DEBUG equ 0
CONFIG_EXCLUDE_SIMD_MISMATCH equ 0
CONFIG_GCOV equ 0
CONFIG_GPROF equ 0
CONFIG_LIBVMAF_PSNR_PEAK equ 1
CONFIG_MAX_DECODE_PROFILE equ 2
CONFIG_OS_SUPPORT equ 1
CONFIG_SHARED equ 0
CONFIG_SVT_AV1 equ 1
DECODE_HEIGHT_LIMIT equ 0
DECODE_WIDTH_LIMIT equ 0
HAVE_WXWIDGETS equ 0
STATIC_LINK_JXL equ 0
"""

_ASM_ISA_X86_64 = """\
HAVE_ARM_CRC32 equ 0
HAVE_AVX equ 1
HAVE_AVX2 equ 1
HAVE_AVX512 equ 0
HAVE_MMX equ 1
HAVE_NEON equ 0
HAVE_NEON_DOTPROD equ 0
HAVE_NEON_I8MM equ 0
HAVE_RVV equ 0
HAVE_SSE equ 1
HAVE_SSE2 equ 1
HAVE_SSE3 equ 1
HAVE_SSE4_1 equ 1
HAVE_SSE4_2 equ 1
HAVE_SSSE3 equ 1
HAVE_SVE equ 0
HAVE_SVE2 equ 0
HAVE_VSX equ 0
"""

# =========================================================================
# Other generated file content
# =========================================================================

_AOM_CONFIG_C_CONTENT = """\
#include "aom/aom_codec.h"
static const char* const cfg = "bazel build";
const char *aom_codec_build_config(void) {return cfg;}
"""

_AOM_VERSION_H_CONTENT = """\
#ifndef AOM_VERSION_H_
#define AOM_VERSION_H_
#define VERSION_MAJOR 3
#define VERSION_MINOR 13
#define VERSION_PATCH 3
#define VERSION_EXTRA ""
#define VERSION_PACKED \\
  ((VERSION_MAJOR << 16) | (VERSION_MINOR << 8) | (VERSION_PATCH))
#define VERSION_STRING_NOSP "v3.13.3"
#define VERSION_STRING " v3.13.3"
#endif  // AOM_VERSION_H_
"""

# =========================================================================
# Public macros
# =========================================================================

def aom_config_h(*, name, out):
    """Generates config/aom_config.h with platform-specific and flag-driven defines."""
    _gen_config_file(
        name = name,
        out = out,
        content = _H_GUARD_OPEN +
                  select({
                      "@platforms//cpu:aarch64": _H_ARCH_AARCH64,
                      "@platforms//cpu:x86_64": _H_ARCH_X86_64,
                  }) +
                  _h_flags(_FLAG_DEFINES) +
                  # Special: REALTIME_ONLY=1 implies QUANT_MATRIX=0 and vice versa.
                  select({
                      ":realtime_only_enabled": "#define CONFIG_QUANT_MATRIX 0\n#define CONFIG_REALTIME_ONLY 1\n",
                      "//conditions:default": "#define CONFIG_QUANT_MATRIX 1\n#define CONFIG_REALTIME_ONLY 0\n",
                  }) +
                  # Special: compound condition (encoder=on AND realtime_only=off).
                  select({
                      ":encoder_non_rt": "#define CONFIG_DISABLE_FULL_PIXEL_SPLIT_8X8 1\n",
                      "//conditions:default": "#define CONFIG_DISABLE_FULL_PIXEL_SPLIT_8X8 0\n",
                  }) +
                  select({
                      "@platforms//os:windows": _H_PLATFORM_WINDOWS,
                      "//conditions:default": _H_PLATFORM_UNIX,
                  }) +
                  _H_CONFIG_FIXED +
                  select({
                      "@platforms//cpu:aarch64": _H_ISA_AARCH64,
                      "@platforms//cpu:x86_64": _H_ISA_X86_64,
                  }) +
                  _H_GUARD_CLOSE,
    )

def aom_config_c(*, name, out):
    """Generates config/aom_config.c with build config string."""
    write_file(
        name = name,
        out = out,
        content = _AOM_CONFIG_C_CONTENT.splitlines(),
    )

def aom_version_h(*, name, out):
    """Generates config/aom_version.h with version defines."""
    write_file(
        name = name,
        out = out,
        content = _AOM_VERSION_H_CONTENT.splitlines(),
    )

def aom_config_asm(*, name, out):
    """Generates config/aom_config.asm (x86_64 NASM equ format) with flag-driven values."""
    _gen_config_file(
        name = name,
        out = out,
        content = _ASM_ARCH +
                  _asm_flags(_FLAG_DEFINES) +
                  # Special: REALTIME_ONLY=1 implies QUANT_MATRIX=0 and vice versa.
                  select({
                      ":realtime_only_enabled": "CONFIG_QUANT_MATRIX equ 0\nCONFIG_REALTIME_ONLY equ 1\n",
                      "//conditions:default": "CONFIG_QUANT_MATRIX equ 1\nCONFIG_REALTIME_ONLY equ 0\n",
                  }) +
                  # Special: compound condition (encoder=on AND realtime_only=off).
                  select({
                      ":encoder_non_rt": "CONFIG_DISABLE_FULL_PIXEL_SPLIT_8X8 equ 1\n",
                      "//conditions:default": "CONFIG_DISABLE_FULL_PIXEL_SPLIT_8X8 equ 0\n",
                  }) +
                  select({
                      "@platforms//os:windows": _ASM_PLATFORM_WINDOWS,
                      "//conditions:default": _ASM_PLATFORM_UNIX,
                  }) +
                  _ASM_CONFIG_FIXED +
                  _ASM_ISA_X86_64,
    )
