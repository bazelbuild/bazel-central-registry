// Hand-authored replacement for the CMake-generated config.h of xerces-c (bundled under lib/xerces). Covers a
// POSIX build (Linux glibc + macOS) with the IconvGNU transcoder, InMemory message loader, POSIX file/mutex
// managers and no network accessor. Included by xerces sources under HAVE_CONFIG_H, which the build system sets.
// Only macros relevant to the compiled subset are defined; the rest are left off.
#ifndef MSIX_XERCES_CONFIG_H
#define MSIX_XERCES_CONFIG_H

// --- headers present on both Linux glibc and macOS ---
#define HAVE_CTYPE_H 1
#define HAVE_DLFCN_H 1
#define HAVE_ERRNO_H 1
#define HAVE_FCNTL_H 1
#define HAVE_FLOAT_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_LANGINFO_H 1
#define HAVE_LIMITS_H 1
#define HAVE_LOCALE_H 1
#define HAVE_MEMORY_H 1
#define HAVE_NETDB_H 1
#define HAVE_NETINET_IN_H 1
#define HAVE_STDBOOL_H 1
#define HAVE_STDDEF_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_STRINGS_H 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TIMEB_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1
#define HAVE_WCHAR_H 1
#define HAVE_WCTYPE_H 1
#define HAVE_ARPA_INET_H 1
#define HAVE_ICONV_H 1

// endian header differs between glibc and macOS/BSD
#if defined(__APPLE__)
#define HAVE_MACHINE_ENDIAN_H 1
#else
#define HAVE_ENDIAN_H 1
#endif

// --- functions ---
#define HAVE_CLOCK_GETTIME 1
#define HAVE_FTIME 1
#define HAVE_GETADDRINFO 1
#define HAVE_GETCWD 1
#define HAVE_GETHOSTBYADDR 1
#define HAVE_GETHOSTBYNAME 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_GMTIME_R 1
#define HAVE_ICONV 1
#define HAVE_ICONV_CLOSE 1
#define HAVE_ICONV_OPEN 1
#define HAVE_LOCALECONV 1
#define HAVE_MBLEN 1
#define HAVE_MBRLEN 1
#define HAVE_MBSRTOWCS 1
#define HAVE_MBSTOWCS 1
#define HAVE_MEMMOVE 1
#define HAVE_MEMSET 1
#define HAVE_NL_LANGINFO 1
#define HAVE_PATHCONF 1
#define HAVE_PTHREAD 1
#define HAVE_REALPATH 1
#define HAVE_SETLOCALE 1
#define HAVE_SNPRINTF 1
#define HAVE_SOCKET 1
#define HAVE_STRCASECMP 1
#define HAVE_STRCHR 1
#define HAVE_STRDUP 1
#define HAVE_STRNCASECMP 1
#define HAVE_STRRCHR 1
#define HAVE_STRSTR 1
#define HAVE_STRTOL 1
#define HAVE_STRTOUL 1
#define HAVE_TIMEGM 1
#define HAVE_TOWLOWER 1
#define HAVE_TOWUPPER 1
#define HAVE_WCSRTOMBS 1
#define HAVE_WCSTOMBS 1

// --- language / library features ---
#define HAVE_BOOL 1
#define HAVE_CONST 1
#define HAVE_CSTDINT 1
#define HAVE_INLINE 1
#define HAVE_NAMESPACES 1
#define HAVE_STD_NAMESPACE 1
#define HAVE_STD_LIBS 1
#define HAVE_VOLATILE 1
#define HAVE_PATH_MAX 1

// Both glibc's iconv and macOS's system iconv take a non-const `char**`, so ICONV_USES_CONST_POINTER stays off.

// --- sizes (LP64 on both Linux and macOS) ---
#define SIZEOF_SHORT 2
#define SIZEOF_INT 4
#define SIZEOF_LONG 8
#define SIZEOF_LONG_LONG 8
#define SIZEOF_WCHAR_T 4

// --- package identity ---
#define PACKAGE "xerces-c"
#define PACKAGE_NAME "xerces-c"
#define PACKAGE_TARNAME "xerces-c"
#define PACKAGE_VERSION "3.2.1"
#define PACKAGE_STRING "xerces-c 3.2.1"
#define PACKAGE_BUGREPORT ""
#define PACKAGE_URL ""
#define VERSION "3.2.1"

// --- subsystem selection (POSIX, pack-only, no network / ICU) ---
#define XERCES_USE_TRANSCODER_GNUICONV 1
#define XERCES_USE_MSGLOADER_INMEMORY 1
#define XERCES_USE_FILEMGR_POSIX 1
#define XERCES_USE_MUTEXMGR_POSIX 1

#endif
