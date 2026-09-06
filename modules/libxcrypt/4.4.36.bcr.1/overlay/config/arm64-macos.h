/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

#ifndef _CRYPT_CONFIG_H
#define _CRYPT_CONFIG_H 1

/* Define to 1 if crypt and crypt_r should return a "failure token" on
   failure, or 0 if they should return NULL. */
#define ENABLE_FAILURE_TOKENS 0

/* Define as 1 if the obsolete APIs (fcrypt, encrypt, setkey) should be
   included, 0 otherwise. */
#define ENABLE_OBSOLETE_API 0

/* Define to 1 if fcrypt, encrypt{,_r}, setkey{,_r} should set errno to
   ENOSYS, or 0 if they should perform real operations. */
#define ENABLE_OBSOLETE_API_ENOSYS 0

/* Define as an #if expression that is true when compiling for a big-endian
   CPU. */
#define ENDIANNESS_IS_BIG (BYTE_ORDER == BIG_ENDIAN)

/* Define as an #if expression that is true when compiling for a little-endian
   CPU. */
#define ENDIANNESS_IS_LITTLE (BYTE_ORDER == LITTLE_ENDIAN)

/* Define as an #if expression that is true when compiling for a PDP-endian
   CPU. */
#define ENDIANNESS_IS_PDP (BYTE_ORDER == PDP_ENDIAN)

/* Define to 1 if you have the 'arc4random_buf' function. */
#define HAVE_ARC4RANDOM_BUF 1

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you have the <endian.h> header file. */
/* #undef HAVE_ENDIAN_H */

/* Define to 1 if you have the 'explicit_bzero' function. */
/* #undef HAVE_EXPLICIT_BZERO */

/* Define to 1 if you have the 'explicit_memset' function. */
/* #undef HAVE_EXPLICIT_MEMSET */

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if the system has the `symver' function attribute */
/* #undef HAVE_FUNC_ATTRIBUTE_SYMVER */

/* Define to 1 if you have the 'getentropy' function. */
#define HAVE_GETENTROPY 1

/* Define to 1 if you have the 'getrandom' function. */
/* #undef HAVE_GETRANDOM */

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if -Wl,--wrap,SYMBOL can be used to intercept calls to SYMBOL
   at link time. */
/* #undef HAVE_LD_WRAP */

/* Define if stddef.h provides max_align_t. */
#define HAVE_MAX_ALIGN_T 1

/* Define to 1 if you have the 'memset_s' function. */
#define HAVE_MEMSET_S 1

/* Define to 1 if you have the <minix/config.h> header file. */
/* #undef HAVE_MINIX_CONFIG_H */

/* Define to 1 if you have the 'open64' function. */
/* #undef HAVE_OPEN64 */

/* Define if <assert.h> defines static_assert. */
#define HAVE_STATIC_ASSERT_IN_ASSERT_H 1

/* Define to 1 if you have the <stdbool.h> header file. */
#define HAVE_STDBOOL_H 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdio.h> header file. */
#define HAVE_STDIO_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define as 1 if symbol versioning is enabled and applied. */
#define HAVE_SYMVER 0

/* Define to 1 if you have the 'syscall' function. */
#define HAVE_SYSCALL 1

/* Define if <sys/cdefs.h> defines __BEGIN_DECLS and __END_DECLS. */
#define HAVE_SYS_CDEFS_BEGIN_END_DECLS 1

/* Define to 1 if you have the <sys/cdefs.h> header file. */
#define HAVE_SYS_CDEFS_H 1

/* Define if <sys/cdefs.h> defines __THROW. */
/* #undef HAVE_SYS_CDEFS_THROW */

/* Define to 1 if you have the <sys/endian.h> header file. */
/* #undef HAVE_SYS_ENDIAN_H */

/* Define to 1 if you have the <sys/param.h> header file. */
#define HAVE_SYS_PARAM_H 1

/* Define to 1 if you have the <sys/random.h> header file. */
#define HAVE_SYS_RANDOM_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/syscall.h> header file. */
#define HAVE_SYS_SYSCALL_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <ucontext.h> header file. */
/* #undef HAVE_UCONTEXT_H */

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if you have the <valgrind/valgrind.h> header file. */
/* #undef HAVE_VALGRIND_VALGRIND_H */

/* Define to 1 if you have the <wchar.h> header file. */
#define HAVE_WCHAR_H 1

/* Define if the compiler supports the _Static_assert intrinsic. */
/* #undef HAVE__STATIC_ASSERT */

/* Define to the sub-directory where libtool stores uninstalled libraries. */
#define LT_OBJDIR ".libs/"

/* Name of package */
#define PACKAGE "libxcrypt"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "https://github.com/bazelbuild/bazel-central-registry/issues"

/* Define to the full name of this package. */
#define PACKAGE_NAME "xcrypt"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "xcrypt 4.4.36"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "libxcrypt"

/* Define to the home page for this package. */
#define PACKAGE_URL "https://github.com/bazelbuild/bazel-central-registry"

/* Define to the version of this package. */
#define PACKAGE_VERSION "4.4.36"

/* Define to 1 if all of the C89 standard headers exist (not just the ones
   required in a freestanding environment). This macro is provided for
   backward compatibility; new code need not use it. */
#define STDC_HEADERS 1

/* Define as the lowest compatibility symbol version that is actually included
   in libcrypt.so. */
#define SYMVER_FLOOR XCRYPT_2.0

/* Define to 1 if getcontext, setcontext, makecontext, and swapcontext are
   available from ucontext.h without deprecation warnings. */
/* #undef USE_SWAPCONTEXT */

/* Enable extensions on AIX, Interix, z/OS.  */
#ifndef _ALL_SOURCE
# define _ALL_SOURCE 1
#endif
/* Enable general extensions on macOS.  */
#ifndef _DARWIN_C_SOURCE
# define _DARWIN_C_SOURCE 1
#endif
/* Enable general extensions on Solaris.  */
#ifndef __EXTENSIONS__
# define __EXTENSIONS__ 1
#endif
/* Enable GNU extensions on systems that have them.  */
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif
/* Enable X/Open compliant socket functions that do not require linking
   with -lxnet on HP-UX 11.11.  */
#ifndef _HPUX_ALT_XOPEN_SOCKET_API
# define _HPUX_ALT_XOPEN_SOCKET_API 1
#endif
/* Identify the host operating system as Minix.
   This macro does not affect the system headers' behavior.
   A future release of Autoconf may stop defining this macro.  */
#ifndef _MINIX
/* # undef _MINIX */
#endif
/* Enable general extensions on NetBSD.
   Enable NetBSD compatibility extensions on Minix.  */
#ifndef _NETBSD_SOURCE
# define _NETBSD_SOURCE 1
#endif
/* Enable OpenBSD compatibility extensions on NetBSD.
   Oddly enough, this does nothing on OpenBSD.  */
#ifndef _OPENBSD_SOURCE
# define _OPENBSD_SOURCE 1
#endif
/* Define to 1 if needed for POSIX-compatible behavior.  */
#ifndef _POSIX_SOURCE
/* # undef _POSIX_SOURCE */
#endif
/* Define to 2 if needed for POSIX-compatible behavior.  */
#ifndef _POSIX_1_SOURCE
/* # undef _POSIX_1_SOURCE */
#endif
/* Enable POSIX-compatible threading on Solaris.  */
#ifndef _POSIX_PTHREAD_SEMANTICS
# define _POSIX_PTHREAD_SEMANTICS 1
#endif
/* Enable extensions specified by ISO/IEC TS 18661-5:2014.  */
#ifndef __STDC_WANT_IEC_60559_ATTRIBS_EXT__
# define __STDC_WANT_IEC_60559_ATTRIBS_EXT__ 1
#endif
/* Enable extensions specified by ISO/IEC TS 18661-1:2014.  */
#ifndef __STDC_WANT_IEC_60559_BFP_EXT__
# define __STDC_WANT_IEC_60559_BFP_EXT__ 1
#endif
/* Enable extensions specified by ISO/IEC TS 18661-2:2015.  */
#ifndef __STDC_WANT_IEC_60559_DFP_EXT__
# define __STDC_WANT_IEC_60559_DFP_EXT__ 1
#endif
/* Enable extensions specified by C23 Annex F.  */
#ifndef __STDC_WANT_IEC_60559_EXT__
# define __STDC_WANT_IEC_60559_EXT__ 1
#endif
/* Enable extensions specified by ISO/IEC TS 18661-4:2015.  */
#ifndef __STDC_WANT_IEC_60559_FUNCS_EXT__
# define __STDC_WANT_IEC_60559_FUNCS_EXT__ 1
#endif
/* Enable extensions specified by C23 Annex H and ISO/IEC TS 18661-3:2015.  */
#ifndef __STDC_WANT_IEC_60559_TYPES_EXT__
# define __STDC_WANT_IEC_60559_TYPES_EXT__ 1
#endif
/* Enable extensions specified by ISO/IEC TR 24731-2:2010.  */
#ifndef __STDC_WANT_LIB_EXT2__
# define __STDC_WANT_LIB_EXT2__ 1
#endif
/* Enable extensions specified by ISO/IEC 24747:2009.  */
#ifndef __STDC_WANT_MATH_SPEC_FUNCS__
# define __STDC_WANT_MATH_SPEC_FUNCS__ 1
#endif
/* Enable extensions on HP NonStop.  */
#ifndef _TANDEM_SOURCE
# define _TANDEM_SOURCE 1
#endif
/* Enable X/Open extensions.  Define to 500 only if necessary
   to make mbstate_t available.  */
#ifndef _XOPEN_SOURCE
/* # undef _XOPEN_SOURCE */
#endif


/* Version number of package */
#define VERSION "4.4.36"

/* Define when compiling with ASan. Only affects tests. */
/* #undef XCRYPT_USE_ASAN */

/* Number of bits in a file offset, on hosts where this is settable. */
/* #undef _FILE_OFFSET_BITS */

/* Define to 1 on platforms where this makes off_t a 64-bit type. */
/* #undef _LARGE_FILES */

/* Number of bits in time_t, on hosts where this is settable. */
/* #undef _TIME_BITS */

/* Define to 1 on platforms where this makes time_t a 64-bit type. */
/* #undef __MINGW_USE_VC2005_COMPAT */

/* Define as a type specifier which sets the alignment of a variable or type
   to N bytes. C11 alignas(TYPE) does not need to be supported. */
#define alignas(n) _Alignas(n)

/* Define as an expression which evaluates to the alignment of THING. Must be
   computed at compile time (an "integer constant expression"). */
#define alignof(thing) _Alignof(thing)

#endif /* config.h */
