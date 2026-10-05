#ifndef OPENBLAS_CONFIG_H
#define OPENBLAS_CONFIG_H

#if defined(__linux__)
#define OPENBLAS_OS_LINUX 1
#elif defined(__APPLE__)
#define OPENBLAS_OS_DARWIN 1
#elif defined(_WIN32)
#define OPENBLAS_OS_WINDOWS 1
#define OPENBLAS_OS_WINNT 1
#endif

#if defined(__x86_64__) || defined(_M_X64)
#define OPENBLAS_ARCH_X86_64 1
#elif defined(__aarch64__) || defined(_M_ARM64)
#define OPENBLAS_ARCH_ARM64 1
#elif defined(__i386__) || defined(_M_IX86)
#define OPENBLAS_ARCH_X86 1
#elif defined(__arm__) || defined(_M_ARM)
#define OPENBLAS_ARCH_ARM 1
#endif

#if defined(__GNUC__)
#define OPENBLAS_C_GCC 1
#elif defined(__clang__)
#define OPENBLAS_C_CLANG 1
#elif defined(_MSC_VER)
#define OPENBLAS_C_MSVC 1
#endif

#if defined(__LP64__) || defined(_WIN64) || defined(__x86_64__) || defined(__aarch64__)
#define OPENBLAS___64BIT__ 1
#endif

#define OPENBLAS_FUNDERSCORE
#define OPENBLAS_BUNDERSCORE _
#define OPENBLAS_NEEDBUNDERSCORE 1
#define OPENBLAS_GENERIC
#define OPENBLAS_L1_DATA_SIZE 32768
#define OPENBLAS_L1_DATA_LINESIZE 128
#define OPENBLAS_L2_SIZE 512488
#define OPENBLAS_L2_LINESIZE 128
#define OPENBLAS_DTB_DEFAULT_ENTRIES 128
#define OPENBLAS_DTB_SIZE 4096
#define OPENBLAS_L2_ASSOCIATIVE 8
#define OPENBLAS_CORE_generic
#define OPENBLAS_CHAR_CORENAME "generic"
#define OPENBLAS_SLOCAL_BUFFER_SIZE 4096
#define OPENBLAS_DLOCAL_BUFFER_SIZE 4096
#define OPENBLAS_CLOCAL_BUFFER_SIZE 8192
#define OPENBLAS_ZLOCAL_BUFFER_SIZE 8192
#define OPENBLAS_GEMM_MULTITHREAD_THRESHOLD 4
#define OPENBLAS_VERSION "OpenBLAS 0.3.29"

#if defined(OPENBLAS_OS_WINNT) || defined(OPENBLAS_OS_CYGWIN_NT) || defined(OPENBLAS_OS_INTERIX)
#define OPENBLAS_WINDOWS_ABI
#define OPENBLAS_OS_WINDOWS

#ifdef DOUBLE
#define DOUBLE_DEFINED DOUBLE
#undef  DOUBLE
#endif
#endif

#ifdef OPENBLAS_NEEDBUNDERSCORE
#define BLASFUNC(FUNC) FUNC##_
#else
#define BLASFUNC(FUNC) FUNC
#endif

#ifdef OPENBLAS_QUAD_PRECISION
typedef struct {
  unsigned long x[2];
}  xdouble;
#elif defined OPENBLAS_EXPRECISION
#define xdouble long double
#else
#define xdouble double
#endif

#if defined(OPENBLAS_OS_WINDOWS) && defined(OPENBLAS___64BIT__)
typedef long long BLASLONG;
typedef unsigned long long BLASULONG;
#else
typedef long BLASLONG;
typedef unsigned long BLASULONG;
#endif

#ifndef BFLOAT16
#include <stdint.h>
typedef uint16_t bfloat16;
#endif

#ifdef OPENBLAS_USE64BITINT
typedef BLASLONG blasint;
#else
typedef int blasint;
#endif

#if defined(XDOUBLE) || defined(DOUBLE)
#define FLOATRET	FLOAT
#else
#ifdef NEED_F2CCONV
#define FLOATRET	double
#else
#define FLOATRET	float
#endif
#endif

#include <stdio.h>

#if ((defined(__STDC_IEC_559_COMPLEX__) || __STDC_VERSION__ >= 199901L || \
      (__GNUC__ >= 3 && !defined(__cplusplus))) && !(defined(FORCE_OPENBLAS_COMPLEX_STRUCT))) && !defined(_MSC_VER)
  #define OPENBLAS_COMPLEX_C99
#ifndef __cplusplus
  #include <complex.h>
#endif
  typedef float _Complex openblas_complex_float;
  typedef double _Complex openblas_complex_double;
  typedef xdouble _Complex openblas_complex_xdouble;
  #define openblas_make_complex_float(real, imag)    ((real) + ((imag) * _Complex_I))
  #define openblas_make_complex_double(real, imag)   ((real) + ((imag) * _Complex_I))
  #define openblas_make_complex_xdouble(real, imag)  ((real) + ((imag) * _Complex_I))
  #define openblas_complex_float_real(z)             (creal(z))
  #define openblas_complex_float_imag(z)             (cimag(z))
  #define openblas_complex_double_real(z)            (creal(z))
  #define openblas_complex_double_imag(z)            (cimag(z))
  #define openblas_complex_xdouble_real(z)           (creal(z))
  #define openblas_complex_xdouble_imag(z)           (cimag(z))
#else
  #define OPENBLAS_COMPLEX_STRUCT
  typedef struct { float real, imag; } openblas_complex_float;
  typedef struct { double real, imag; } openblas_complex_double;
  typedef struct { xdouble real, imag; } openblas_complex_xdouble;
  #define openblas_make_complex_float(real, imag)    {(real), (imag)}
  #define openblas_make_complex_double(real, imag)   {(real), (imag)}
  #define openblas_make_complex_xdouble(real, imag)  {(real), (imag)}
  #define openblas_complex_float_real(z)             ((z).real)
  #define openblas_complex_float_imag(z)             ((z).imag)
  #define openblas_complex_double_real(z)            ((z).real)
  #define openblas_complex_double_imag(z)            ((z).imag)
  #define openblas_complex_xdouble_real(z)           ((z).real)
  #define openblas_complex_xdouble_imag(z)           ((z).imag)
#endif

#ifdef OPENBLAS_OS_LINUX
#ifndef _GNU_SOURCE
 #define _GNU_SOURCE
#endif
#include <sched.h>
#endif

#endif /* OPENBLAS_CONFIG_H */
