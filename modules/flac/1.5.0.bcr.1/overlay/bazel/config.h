/*
 * Static replacement for the config.h that FLAC's CMake build generates from
 * config.cmake.h.in. Values that CMake detects at configure time are derived here from
 * compiler/platform macros instead. CPU architecture (FLAC__CPU_X86_64 / FLAC__CPU_IA32)
 * is detected by src/libFLAC/include/private/cpu.h itself.
 */
#ifndef FLAC_BAZEL_CONFIG_H
#define FLAC_BAZEL_CONFIG_H

#define PACKAGE_VERSION "1.5.0"

/* Endianness */
#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define CPU_IS_BIG_ENDIAN 1
#else
#define CPU_IS_BIG_ENDIAN 0
#endif
#define WORDS_BIGENDIAN CPU_IS_BIG_ENDIAN

/* Matches upstream CMake, which never enables 64-bit words. */
#define ENABLE_64_BIT_WORDS 0

/* Ogg support: this module always links @ogg. */
#define OGG_FOUND 1
#define FLAC__HAS_OGG OGG_FOUND

/* SIMD */
#if defined(__x86_64__) || defined(__amd64__) || defined(_M_X64) || defined(_M_AMD64) || \
    defined(__i386__) || defined(_M_IX86)
#define FLAC__HAS_X86INTRIN 1
#define FLAC__ALIGN_MALLOC_DATA 1
#define WITH_AVX 1
#if !defined(_MSC_VER)
#define HAVE_X86INTRIN_H 1
#define HAVE_CPUID_H 1
#endif
#else
#define FLAC__HAS_X86INTRIN 0
#endif

#if defined(__aarch64__) || defined(_M_ARM64)
#define FLAC__CPU_ARM64 1
#define FLAC__HAS_NEONINTRIN 1
#define FLAC__HAS_A64NEONINTRIN 1
#else
#define FLAC__HAS_NEONINTRIN 0
#define FLAC__HAS_A64NEONINTRIN 0
#endif

#ifdef WITH_AVX
#define FLAC__USE_AVX
#endif

/* Operating system */
#if defined(__APPLE__)
#define FLAC__SYS_DARWIN 1
#endif
#if defined(__linux__)
#define FLAC__SYS_LINUX 1
#define HAVE_BYTESWAP_H 1
#endif

/* Compiler builtins */
#if defined(__GNUC__) || defined(__clang__)
#define HAVE_BSWAP16 1
#define HAVE_BSWAP32 1
#define HAVE_TYPEOF 1
#endif

/* Standard headers and functions */
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_LROUND 1

#if !defined(_WIN32)
#define HAVE_FSEEKO 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_UNISTD_H 1
#define HAVE_CLOCK_GETTIME 1
/* ENABLE_MULTITHREADING is ON upstream and uses pthreads where available. */
#define HAVE_PTHREAD 1
#endif

#ifndef _ALL_SOURCE
#define _ALL_SOURCE
#endif
#if !defined(_GNU_SOURCE) && !defined(_WIN32)
#define _GNU_SOURCE
#endif
#ifndef _DARWIN_USE_64_BIT_INODE
#define _DARWIN_USE_64_BIT_INODE 1
#endif
#ifndef _FILE_OFFSET_BITS
#define _FILE_OFFSET_BITS 64
#endif
#ifndef _LARGEFILE_SOURCE
#define _LARGEFILE_SOURCE
#endif

#endif /* FLAC_BAZEL_CONFIG_H */
