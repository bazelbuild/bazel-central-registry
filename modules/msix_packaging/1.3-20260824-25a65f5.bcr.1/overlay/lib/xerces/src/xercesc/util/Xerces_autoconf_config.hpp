// Hand-authored replacement for the CMake-generated Xerces_autoconf_config.hpp (xerces-c bundled under
// lib/xerces). Values are for a POSIX build (Linux glibc + macOS), matching the IconvGNU transcoder
// configuration (XMLCh = char16_t). See also the companion config.h.
#ifndef XERCES_AUTOCONFIG_CONFIG_HPP
#define XERCES_AUTOCONFIG_CONFIG_HPP

#define XERCES_AUTOCONF 1
#define XERCES_HAVE_SYS_TYPES_H 1
#define XERCES_HAVE_CSTDINT 1
#define XERCES_HAVE_STDINT_H 1
#define XERCES_HAVE_INTTYPES_H 1
/* XERCES_HAVE_INTRIN_H — MSVC only */
/* XERCES_HAVE_EMMINTRIN_H — x86 SSE2 only, left off for arm64/x86 portability */
#define XERCES_INCLUDE_WCHAR_H 1

#define XERCES_S16BIT_INT int16_t
#define XERCES_S32BIT_INT int32_t
#define XERCES_S64BIT_INT int64_t
#define XERCES_U16BIT_INT uint16_t
#define XERCES_U32BIT_INT uint32_t
#define XERCES_U64BIT_INT uint64_t
#define XERCES_XMLCH_T char16_t
#define XERCES_SIZE_T size_t
#define XERCES_SSIZE_T ssize_t

#define XERCES_HAS_CPP_NAMESPACE 1
#define XERCES_STD_NAMESPACE 1
#define XERCES_NEW_IOSTREAMS 1
/* XERCES_NO_NATIVE_BOOL — we have bool */
/* XERCES_LSTRSUPPORT — no wide L"" literal support needed */
/* XERCES_MFC_SUPPORT — Windows only */
/* XERCES_HAVE_CPUID_INTRINSIC / SSE2_INTRINSIC / GETCPUID — left off (no SIMD) */
/* XERCES_NO_MATCHING_DELETE_OPERATOR — not needed */
/* XERCES_DLL_EXPORT — we build a static archive */
#define XERCES_STATIC_LIBRARY 1
#define XERCES_PLATFORM_EXPORT
#define XERCES_PLATFORM_IMPORT
#ifdef XERCES_DLL_EXPORT
#  define DLL_EXPORT
#endif

// ---------------------------------------------------------------------------
//  Include standard headers, if available, that we may rely on below.
// ---------------------------------------------------------------------------
#if defined(__cplusplus) && defined(HAVE_CSTDINT)
#  include <cstdint>
#endif
#if XERCES_HAVE_STDINT_H
#  include <stdint.h>
#endif
#if XERCES_HAVE_INTTYPES_H
#  include <inttypes.h>
#endif
#if XERCES_HAVE_SYS_TYPES_H
#  include <sys/types.h>
#endif
#if XERCES_INCLUDE_WCHAR_H
#  include <wchar.h>
#endif

typedef XERCES_SIZE_T				XMLSize_t;
typedef XERCES_SSIZE_T				XMLSSize_t;

#define XERCES_SIZE_MAX SIZE_MAX
#define XERCES_SSIZE_MAX PTRDIFF_MAX

typedef XERCES_XMLCH_T				XMLCh;

typedef XERCES_U16BIT_INT			XMLUInt16;
typedef XERCES_U32BIT_INT			XMLUInt32;
typedef XERCES_U64BIT_INT			XMLUInt64;

typedef XERCES_S16BIT_INT			XMLInt16;
typedef XERCES_S32BIT_INT			XMLInt32;
typedef XERCES_S64BIT_INT			XMLInt64;

typedef XMLUInt64			        XMLFilePos;
typedef XMLUInt64			        XMLFileLoc;

#if defined(_DEBUG)
#define XERCES_DEBUG
#endif

#endif
