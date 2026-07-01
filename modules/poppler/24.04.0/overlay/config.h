#pragma once

// Platform-level detection (HAVE_UNISTD_H, HAVE_DIRENT_H, etc.)
#include <rules_autoconf/config.h>

// Linux/glibc — normally detected by ConfigureChecks.cmake.
#ifndef HAVE_STRTOK_R
#define HAVE_STRTOK_R 1
#endif
#ifndef HAVE_MKSTEMP
#define HAVE_MKSTEMP 1
#endif
#ifndef HAVE_POPEN
#define HAVE_POPEN 1
#endif
#ifndef HAVE_SYS_MMAN_H
#define HAVE_SYS_MMAN_H 1
#endif
#ifndef HAVE_DLFCN_H
#define HAVE_DLFCN_H 1
#endif
#ifndef HAVE_FCNTL_H
#define HAVE_FCNTL_H 1
#endif
#ifndef HAVE_UNISTD_H
#define HAVE_UNISTD_H 1
#endif
#ifndef HAVE_SYS_STAT_H
#define HAVE_SYS_STAT_H 1
#endif
#ifndef HAVE_LIBZ
#define HAVE_LIBZ 1
#endif

// Version
#define POPPLER_VERSION "24.04.0"
#define VERSION "24.04.0"
#define PACKAGE "poppler"
#define PACKAGE_NAME "poppler"
#define PACKAGE_VERSION "24.04.0"
#define PACKAGE_STRING "poppler 24.04.0"
#define PACKAGE_TARNAME "poppler"
#define PACKAGE_BUGREPORT "https://bugs.freedesktop.org/enter_bug.cgi?product=poppler"
#define PACKAGE_URL ""

// Minimal build: pdfinfo + pdftoppm only.
// Optional libraries (libjpeg, libpng, libtiff, openjpeg, curl, NSS3, GPGME, Cairo, CMS,
// fontconfig) and their associated macros are intentionally left undefined.
#define OPI_SUPPORT 1
#define TEXTOUT_WORD_LIST 1
#define DEFAULT_SIGNATURE_BACKEND "None"
#define POPPLER_DATADIR ""
#define ICONV_CONST

// Compiler helpers
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
