#pragma once
#include <rules_autoconf/config.h>

#define PACKAGE "fftw"
#define PACKAGE_VERSION "3.3.10"
#define VERSION "3.3.10"
#define FFTW_CC "bazel"

#define FFTW_ENABLE_ALLOCA 1

#define SIZEOF_UNSIGNED_INT 4
#if defined(__LP64__) || defined(_WIN64) || defined(__x86_64__) || defined(__aarch64__)
#define SIZEOF_VOID_P 8
#define SIZEOF_UNSIGNED_LONG 8
#else
#define SIZEOF_VOID_P 4
#define SIZEOF_UNSIGNED_LONG 4
#endif
#define SIZEOF_UNSIGNED_LONG_LONG 8

#if defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86)
#define HAVE_SSE 1
#define HAVE_SSE2 1
#define HAVE_AVX 1
#define HAVE_AVX2 1
#define HAVE_FMA 1
#endif

#if defined(__aarch64__) || (defined(__ARM_NEON) && defined(FFTW_SINGLE))
#define HAVE_NEON 1
#endif

#ifdef __linux__
#undef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200112L
#endif
