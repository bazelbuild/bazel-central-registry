//========================================================================
//
// poppler-config.h — static Bazel overlay for poppler 24.04.0
//
// Minimal feature set: pdfinfo + pdftoppm, no optional dependencies.
//
//========================================================================

#ifndef POPPLER_CONFIG_H
#define POPPLER_CONFIG_H

// Poppler version
#ifndef POPPLER_VERSION
#define POPPLER_VERSION "24.04.0"
#endif

// OPI comment support (always on)
#ifndef OPI_SUPPORT
#define OPI_SUPPORT 1
#endif

// Word list support in text output (always on)
#ifndef TEXTOUT_WORD_LIST
#define TEXTOUT_WORD_LIST 1
#endif

// No curl support
// POPPLER_HAS_CURL_SUPPORT not defined

// No libjpeg
// ENABLE_LIBJPEG not defined

// No libtiff
// ENABLE_LIBTIFF not defined

// No libpng
// ENABLE_LIBPNG not defined

// No CMS
// USE_CMS not defined

// No Cairo
// HAVE_CAIRO not defined

// Platform feature macros (from rules_autoconf)
#include <config.h>

//------------------------------------------------------------------------
// Compiler helpers (unchanged from upstream template)
//------------------------------------------------------------------------

#if defined(_WIN32) && !defined(_MSC_VER)
#include <windef.h>
#else
#define CDECL
#endif

#if __GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ > 4)
#include <cstdio>
#ifdef __MINGW_PRINTF_FORMAT
#define GCC_PRINTF_FORMAT(fmt_index, va_index) \
    __attribute__((__format__(__MINGW_PRINTF_FORMAT, fmt_index, va_index)))
#else
#define GCC_PRINTF_FORMAT(fmt_index, va_index) \
    __attribute__((__format__(__printf__, fmt_index, va_index)))
#endif
#else
#define GCC_PRINTF_FORMAT(fmt_index, va_index)
#endif

#define popplerCopyright "Copyright 2005-2024 The Poppler Developers - http://poppler.freedesktop.org"
#define xpdfCopyright "Copyright 1996-2011, 2022 Glyph & Cog, LLC"

#endif /* POPPLER_CONFIG_H */
