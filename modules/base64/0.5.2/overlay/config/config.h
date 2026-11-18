// Replaces CMake's cmake/config.h.in. Which SIMD codecs get compiled in is
// decided per target CPU here; at run time lib/codec_choose.c still picks the
// best one the CPU actually supports, so a single binary is correct on any
// CPU of that architecture.
#ifndef BASE64_CONFIG_H
#define BASE64_CONFIG_H

#if defined(__x86_64__) || defined(_M_X64)
#define BASE64_WITH_SSSE3 1
#define BASE64_WITH_SSE41 1
#define BASE64_WITH_SSE42 1
#define BASE64_WITH_AVX 1
#define BASE64_WITH_AVX2 1
#define BASE64_WITH_AVX512 1
#define BASE64_WITH_NEON32 0
#define BASE64_WITH_NEON64 0
#elif defined(__aarch64__) || defined(_M_ARM64)
#define BASE64_WITH_SSSE3 0
#define BASE64_WITH_SSE41 0
#define BASE64_WITH_SSE42 0
#define BASE64_WITH_AVX 0
#define BASE64_WITH_AVX2 0
#define BASE64_WITH_AVX512 0
#define BASE64_WITH_NEON32 0
#define BASE64_WITH_NEON64 1
#else
#define BASE64_WITH_SSSE3 0
#define BASE64_WITH_SSE41 0
#define BASE64_WITH_SSE42 0
#define BASE64_WITH_AVX 0
#define BASE64_WITH_AVX2 0
#define BASE64_WITH_AVX512 0
#define BASE64_WITH_NEON32 0
#define BASE64_WITH_NEON64 0
#endif

#define HAVE_SSSE3 BASE64_WITH_SSSE3
#define HAVE_SSE41 BASE64_WITH_SSE41
#define HAVE_SSE42 BASE64_WITH_SSE42
#define HAVE_AVX BASE64_WITH_AVX
#define HAVE_AVX2 BASE64_WITH_AVX2
#define HAVE_AVX512 BASE64_WITH_AVX512
#define HAVE_NEON32 BASE64_WITH_NEON32
#define HAVE_NEON64 BASE64_WITH_NEON64

#endif  // BASE64_CONFIG_H
