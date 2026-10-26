#ifndef OPENBLAS_CONFIG_H_INTERNAL
#define OPENBLAS_CONFIG_H_INTERNAL

#if defined(__linux__)
#define OS_LINUX 1
#elif defined(__APPLE__)
#define OS_DARWIN 1
#elif defined(_WIN32)
#define OS_WINDOWS 1
#define OS_WINNT 1
#endif

#if defined(__x86_64__) || defined(_M_X64)
#define ARCH_X86_64 1
#elif defined(__aarch64__) || defined(_M_ARM64)
#define ARCH_ARM64 1
#elif defined(__i386__) || defined(_M_IX86)
#define ARCH_X86 1
#elif defined(__arm__) || defined(_M_ARM)
#define ARCH_ARM 1
#endif

#if defined(__GNUC__)
#define C_GCC 1
#elif defined(__clang__)
#define C_CLANG 1
#elif defined(_MSC_VER)
#define C_MSVC 1
#endif

#if defined(__LP64__) || defined(_WIN64) || defined(__x86_64__) || defined(__aarch64__)
#define __64BIT__ 1
#endif

#define FUNDERSCORE
#define BUNDERSCORE _
#define NEEDBUNDERSCORE 1
#define GENERIC 1
#define L1_DATA_SIZE 32768
#define L1_DATA_LINESIZE 128
#define L2_SIZE 512488
#define L2_LINESIZE 128
#define DTB_DEFAULT_ENTRIES 128
#define DTB_SIZE 4096
#define L2_ASSOCIATIVE 8
#define CORE_generic
#define CHAR_CORENAME "generic"
#define SLOCAL_BUFFER_SIZE 4096
#define DLOCAL_BUFFER_SIZE 4096
#define CLOCAL_BUFFER_SIZE 8192
#define ZLOCAL_BUFFER_SIZE 8192
#define GEMM_MULTITHREAD_THRESHOLD 4
#define PTHREAD_CREATE_FUNC pthread_create

#endif
