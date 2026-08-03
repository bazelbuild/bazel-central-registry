"""Generates vpx_config.h and vpx_config.asm from platform parameters.

Instead of maintaining separate static config headers per platform that
drift apart, this module generates them from a unified set of parameters.
The output matches what upstream's ./configure produces for each target.
"""
load("@bazel_skylib//rules:write_file.bzl", "write_file")

_ARCH_X86_64 = {
    "ARCH_ARM": 0,
    "ARCH_AARCH64": 0,
    "ARCH_MIPS": 0,
    "ARCH_X86": 0,
    "ARCH_X86_64": 1,
    "ARCH_PPC": 0,
    "ARCH_LOONGARCH": 0,
    "VPX_ARCH_ARM": 0,
    "VPX_ARCH_AARCH64": 0,
    "VPX_ARCH_MIPS": 0,
    "VPX_ARCH_X86": 0,
    "VPX_ARCH_X86_64": 1,
    "VPX_ARCH_PPC": 0,
    "VPX_ARCH_LOONGARCH": 0,
    "HAVE_X86_ASM": 1,
    "HAVE_NEON_ASM": 0,
    "HAVE_NEON": 0,
    "HAVE_NEON_DOTPROD": 0,
    "HAVE_NEON_I8MM": 0,
    "HAVE_SVE": 0,
    "HAVE_SVE2": 0,
    "HAVE_MIPS32": 0,
    "HAVE_DSPR2": 0,
    "HAVE_MSA": 0,
    "HAVE_MIPS64": 0,
    "HAVE_MMX": 1,
    "HAVE_SSE": 1,
    "HAVE_SSE2": 1,
    "HAVE_SSE3": 1,
    "HAVE_SSSE3": 1,
    "HAVE_SSE4_1": 1,
    "HAVE_AVX": 1,
    "HAVE_AVX2": 1,
    "HAVE_AVX512": 0,
    "HAVE_VSX": 0,
    "HAVE_MMI": 0,
    "HAVE_LSX": 0,
    "HAVE_LASX": 0,
}

_ARCH_X86 = {
    "ARCH_ARM": 0,
    "ARCH_AARCH64": 0,
    "ARCH_MIPS": 0,
    "ARCH_X86": 1,
    "ARCH_X86_64": 0,
    "ARCH_PPC": 0,
    "ARCH_LOONGARCH": 0,
    "VPX_ARCH_ARM": 0,
    "VPX_ARCH_AARCH64": 0,
    "VPX_ARCH_MIPS": 0,
    "VPX_ARCH_X86": 1,
    "VPX_ARCH_X86_64": 0,
    "VPX_ARCH_PPC": 0,
    "VPX_ARCH_LOONGARCH": 0,
    "HAVE_X86_ASM": 1,
    "HAVE_NEON_ASM": 0,
    "HAVE_NEON": 0,
    "HAVE_NEON_DOTPROD": 0,
    "HAVE_NEON_I8MM": 0,
    "HAVE_SVE": 0,
    "HAVE_SVE2": 0,
    "HAVE_MIPS32": 0,
    "HAVE_DSPR2": 0,
    "HAVE_MSA": 0,
    "HAVE_MIPS64": 0,
    "HAVE_MMX": 1,
    "HAVE_SSE": 1,
    "HAVE_SSE2": 1,
    "HAVE_SSE3": 1,
    "HAVE_SSSE3": 1,
    "HAVE_SSE4_1": 1,
    "HAVE_AVX": 1,
    "HAVE_AVX2": 1,
    "HAVE_AVX512": 0,
    "HAVE_VSX": 0,
    "HAVE_MMI": 0,
    "HAVE_LSX": 0,
    "HAVE_LASX": 0,
}

_ARCH_ARM64 = {
    "ARCH_ARM": 0,
    "ARCH_AARCH64": 1,
    "ARCH_MIPS": 0,
    "ARCH_X86": 0,
    "ARCH_X86_64": 0,
    "ARCH_PPC": 0,
    "ARCH_LOONGARCH": 0,
    "VPX_ARCH_ARM": 1,
    "VPX_ARCH_AARCH64": 1,
    "VPX_ARCH_MIPS": 0,
    "VPX_ARCH_X86": 0,
    "VPX_ARCH_X86_64": 0,
    "VPX_ARCH_PPC": 0,
    "VPX_ARCH_LOONGARCH": 0,
    "HAVE_NEON_ASM": 0,
    "HAVE_NEON": 1,
    "HAVE_NEON_DOTPROD": 1,
    "HAVE_NEON_I8MM": 1,
    "HAVE_SVE": 1,
    "HAVE_SVE2": 0,
    "HAVE_MIPS32": 0,
    "HAVE_DSPR2": 0,
    "HAVE_MSA": 0,
    "HAVE_MIPS64": 0,
    "HAVE_MMX": 0,
    "HAVE_SSE": 0,
    "HAVE_SSE2": 0,
    "HAVE_SSE3": 0,
    "HAVE_SSSE3": 0,
    "HAVE_SSE4_1": 0,
    "HAVE_AVX": 0,
    "HAVE_AVX2": 0,
    "HAVE_AVX512": 0,
    "HAVE_VSX": 0,
    "HAVE_MMI": 0,
    "HAVE_LSX": 0,
    "HAVE_LASX": 0,
}

_ARCH_ARM = {
    "ARCH_ARM": 1,
    "ARCH_AARCH64": 0,
    "ARCH_MIPS": 0,
    "ARCH_X86": 0,
    "ARCH_X86_64": 0,
    "ARCH_PPC": 0,
    "ARCH_LOONGARCH": 0,
    "VPX_ARCH_ARM": 1,
    "VPX_ARCH_AARCH64": 0,
    "VPX_ARCH_MIPS": 0,
    "VPX_ARCH_X86": 0,
    "VPX_ARCH_X86_64": 0,
    "VPX_ARCH_PPC": 0,
    "VPX_ARCH_LOONGARCH": 0,
    "HAVE_X86_ASM": 0,
    "HAVE_NEON_ASM": 1,
    "HAVE_NEON": 1,
    "HAVE_NEON_DOTPROD": 0,
    "HAVE_NEON_I8MM": 0,
    "HAVE_SVE": 0,
    "HAVE_SVE2": 0,
    "HAVE_MIPS32": 0,
    "HAVE_DSPR2": 0,
    "HAVE_MSA": 0,
    "HAVE_MIPS64": 0,
    "HAVE_MMX": 0,
    "HAVE_SSE": 0,
    "HAVE_SSE2": 0,
    "HAVE_SSE3": 0,
    "HAVE_SSSE3": 0,
    "HAVE_SSE4_1": 0,
    "HAVE_AVX": 0,
    "HAVE_AVX2": 0,
    "HAVE_AVX512": 0,
    "HAVE_VSX": 0,
    "HAVE_MMI": 0,
    "HAVE_LSX": 0,
    "HAVE_LASX": 0,
}

_ARCHES = {
    "x86": _ARCH_X86,
    "x86_64": _ARCH_X86_64,
    "arm": _ARCH_ARM,
    "arm64": _ARCH_ARM64,
}

_COMMON_CONFIG = {
    "HAVE_VPX_PORTS": 1,
    "HAVE_PTHREAD_H": 1,
    "HAVE_UNISTD_H": 1,
    "CONFIG_DEPENDENCY_TRACKING": 1,
    "CONFIG_EXTERNAL_BUILD": 1,
    "CONFIG_INSTALL_DOCS": 0,
    "CONFIG_INSTALL_BINS": 1,
    "CONFIG_INSTALL_LIBS": 1,
    "CONFIG_INSTALL_SRCS": 0,
    "CONFIG_DEBUG": 0,
    "CONFIG_GPROF": 0,
    "CONFIG_GCOV": 0,
    "CONFIG_RVCT": 0,
    "CONFIG_GCC": 1,
    "CONFIG_MSVS": 0,
    "CONFIG_PIC": 1,
    "CONFIG_BIG_ENDIAN": 0,
    "CONFIG_CODEC_SRCS": 0,
    "CONFIG_DEBUG_LIBS": 0,
    "CONFIG_DEQUANT_TOKENS": 0,
    "CONFIG_DC_RECON": 0,
    "CONFIG_RUNTIME_CPU_DETECT": 1,
    "CONFIG_POSTPROC": 1,
    "CONFIG_VP9_POSTPROC": 1,
    "CONFIG_MULTITHREAD": 1,
    "CONFIG_INTERNAL_STATS": 0,
    "CONFIG_VP8_ENCODER": 1,
    "CONFIG_VP8_DECODER": 1,
    "CONFIG_VP9_ENCODER": 1,
    "CONFIG_VP9_DECODER": 1,
    "CONFIG_VP8": 1,
    "CONFIG_VP9": 1,
    "CONFIG_ENCODERS": 1,
    "CONFIG_DECODERS": 1,
    "CONFIG_STATIC_MSVCRT": 0,
    "CONFIG_SPATIAL_RESAMPLING": 1,
    "CONFIG_REALTIME_ONLY": 1,
    "CONFIG_ONTHEFLY_BITPACKING": 0,
    "CONFIG_ERROR_CONCEALMENT": 0,
    "CONFIG_SHARED": 0,
    "CONFIG_STATIC": 1,
    "CONFIG_SMALL": 0,
    "CONFIG_POSTPROC_VISUALIZER": 0,
    "CONFIG_OS_SUPPORT": 1,
    "CONFIG_UNIT_TESTS": 1,
    "CONFIG_WEBM_IO": 1,
    "CONFIG_LIBYUV": 0,
    "CONFIG_DECODE_PERF_TESTS": 0,
    "CONFIG_ENCODE_PERF_TESTS": 0,
    "CONFIG_MULTI_RES_ENCODING": 1,
    "CONFIG_TEMPORAL_DENOISING": 1,
    "CONFIG_VP9_TEMPORAL_DENOISING": 1,
    "CONFIG_COEFFICIENT_RANGE_CHECKING": 0,
    "CONFIG_VP9_HIGHBITDEPTH": 0,
    "CONFIG_BETTER_HW_COMPATIBILITY": 0,
    "CONFIG_EXPERIMENTAL": 0,
    "CONFIG_SIZE_LIMIT": 1,
    "DECODE_WIDTH_LIMIT": 16384,
    "DECODE_HEIGHT_LIMIT": 16384,
    "CONFIG_ALWAYS_ADJUST_BPM": 0,
    "CONFIG_BITSTREAM_DEBUG": 0,
    "CONFIG_MISMATCH_DEBUG": 0,
    "CONFIG_FP_MB_STATS": 0,
    "CONFIG_EMULATE_HARDWARE": 0,
    "CONFIG_NON_GREEDY_MV": 0,
    "CONFIG_COLLECT_COMPONENT_TIMING": 0,
}

_WINDOWS_CONFIG = {
    "CONFIG_GCC": 0,
    "CONFIG_MSVS": 1,
    "CONFIG_PIC": 0,
    "HAVE_PTHREAD_H": 0,
    "HAVE_UNISTD_H": 0,
}

_LICENSE_COMMENT = """\
/* Copyright (c) 2011 The WebM project authors. All Rights Reserved. */
/*  */
/* Use of this source code is governed by a BSD-style license */
/* that can be found in the LICENSE file in the root of the source */
/* tree. An additional intellectual property rights grant can be found */
/* in the file PATENTS.  All contributing project authors may */
/* be found in the AUTHORS file in the root of the source tree. */
/* This file automatically generated by configure. Do not edit! */"""

def _build_defines(arch, features, windows = False):
    if arch not in _ARCHES:
        fail("Unsupported architecture: %s" % arch)
    defines = {}
    defines.update(_ARCHES[arch])
    defines.update(_COMMON_CONFIG)
    if windows:
        defines.update(_WINDOWS_CONFIG)
    defines.update(features)
    return defines

def _define_order(arch):
    """Returns the ordered list of define keys matching upstream output."""
    keys = list(_ARCHES[arch].keys()) + list(_COMMON_CONFIG.keys())
    seen = {}
    ordered = []
    for k in keys:
        if k not in seen:
            seen[k] = True
            ordered.append(k)
    return ordered

def _ordered_lines(order, defines, prefix, features):
    lines = []
    for k in order:
        if k in defines:
            lines.append("%s %s %s" % (prefix, k, defines[k]))
    for k in features:
        if k not in order and k in defines:
            lines.append("%s %s %s" % (prefix, k, defines[k]))
    return lines

def _ordered_define_items(order, defines, features):
    items = []
    for k in order:
        if k in defines:
            items.append((k, defines[k]))
    for k in features:
        if k not in order and k in defines:
            items.append((k, defines[k]))
    return items

def vpx_config_header(name, arch, out, features = {}, windows = False):
    """Generates a vpx_config.h file.

    Args:
        name: Rule name.
        arch: "x86", "x86_64", "arm", or "arm64".
        out: Output file path for vpx_config.h.
        features: Dict of CONFIG_* overrides.
        windows: Whether to apply Windows-specific overrides.
    """
    defines = _build_defines(arch, features, windows = windows)
    order = _define_order(arch)
    lines = [_LICENSE_COMMENT, "#ifndef VPX_CONFIG_H", "#define VPX_CONFIG_H", "#define RESTRICT    ", "#define INLINE      inline"]
    lines.extend(_ordered_lines(order, defines, "#define", features))
    lines.append("#endif /* VPX_CONFIG_H */")

    write_file(
        name = name,
        out = out,
        content = lines,
    )

def vpx_config_asm(name, arch, out, features = {}, windows = False):
    """Generates a vpx_config.asm file.

    Args:
        name: Rule name.
        arch: "x86", "x86_64", "arm", or "arm64".
        out: Output file path for vpx_config.asm.
        features: Dict of CONFIG_* overrides.
        windows: Whether to apply Windows-specific overrides.
    """
    defines = _build_defines(arch, features, windows = windows)
    order = _define_order(arch)
    if arch in ["x86", "x86_64"]:
        lines = _ordered_lines(order, defines, "%define", features)
    else:
        lines = ["@ This file was created from a .asm file", "@  using the ads2gas.pl script.", ".syntax unified"]
        for key, value in _ordered_define_items(order, defines, features):
            lines.append(".equ %s ,  %s" % (key, value))
    write_file(
        name = name,
        out = out,
        content = lines,
    )

def vpx_config_rtcd(name, arch, out, features = {}, windows = False):
    """Generates the rtcd.pl config input from platform parameters."""
    defines = _build_defines(arch, features, windows = windows)
    order = _define_order(arch)
    lines = []
    for key, value in _ordered_define_items(order, defines, features):
        if not (key.startswith("CONFIG_") or key.startswith("HAVE_")):
            continue
        value = str(value)
        if value == "1":
            value = "yes"
        elif value == "0":
            value = "no"
        lines.append("%s=%s" % (key, value))
    write_file(
        name = name,
        out = out,
        content = lines,
    )
