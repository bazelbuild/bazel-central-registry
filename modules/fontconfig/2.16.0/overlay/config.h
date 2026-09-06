/* Hand-written replacement for the meson/autotools-generated config.h,
 * for the Bazel Central Registry overlay build.
 *
 * Values mirror what upstream meson.build (2.16.0) detects on the two
 * supported platforms: Linux/glibc and macOS.  The XML backend is expat;
 * libxml2, NLS, iconv and Fontations stay disabled.  64-bit only (matches
 * the BCR presubmit platforms); config-fixups.h re-derives the size/align
 * macros on Apple targets.
 */
#ifndef FC_BAZEL_CONFIG_H
#define FC_BAZEL_CONFIG_H

#ifndef _GNU_SOURCE
#define _GNU_SOURCE 1
#endif

/* Runtime configuration paths (distro defaults; overridable at runtime via
 * the FONTCONFIG_FILE / FONTCONFIG_PATH / FONTCONFIG_SYSROOT env vars). */
#define FONTCONFIG_PATH "/etc/fonts"
#define CONFIGDIR "/etc/fonts/conf.d"
#define FC_CACHEDIR "/var/cache/fontconfig"
#define FC_TEMPLATEDIR "/usr/share/fontconfig/conf.avail"
#define FC_FONTPATH ""

/* Default font directories, embedded in the fallback config used when no
 * fonts.conf is found at runtime (see FcInitFallbackConfig). */
#ifdef __APPLE__
#define FC_DEFAULT_FONTS \
    "\t<dir>/System/Library/Fonts</dir>\n" \
    "\t<dir>/Library/Fonts</dir>\n" \
    "\t<dir>~/Library/Fonts</dir>\n" \
    "\t<dir>/System/Library/Assets/com_apple_MobileAsset_Font3</dir>\n" \
    "\t<dir>/System/Library/Assets/com_apple_MobileAsset_Font4</dir>\n"
#else
#define FC_DEFAULT_FONTS \
    "\t<dir>/usr/share/fonts</dir>\n" \
    "\t<dir>/usr/local/share/fonts</dir>\n"
#endif

/* The shipped pregenerated src/fcobjshash.h declares its lookup functions
 * with `unsigned int len`; this must match (meson probes the gperf
 * version for the same reason). */
#define FC_GPERF_SIZE_T unsigned int

/* C99 flexible array members are supported by all toolchains we build
 * with. */
#define FLEXIBLE_ARRAY_MEMBER /**/

/* 64-bit platforms only; config-fixups.h re-derives these on Apple. */
#define SIZEOF_VOID_P 8
#define ALIGNOF_VOID_P 8
#define ALIGNOF_DOUBLE 8

/* Threading and atomics. */
#define HAVE_PTHREAD 1
#define HAVE_STDATOMIC_PRIMITIVES 1
#define HAVE_SCHED_H 1
#define HAVE_SCHED_YIELD 1

/* Headers present on both Linux/glibc and macOS. */
#define HAVE_DIRENT_H 1
#define HAVE_DLFCN_H 1
#define HAVE_FCNTL_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_MOUNT_H 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_STATVFS_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_TIME_H 1
#define HAVE_UNISTD_H 1
#define HAVE_WCHAR_H 1

/* Functions present on both Linux/glibc and macOS. */
#define HAVE_FSTATFS 1
#define HAVE_FSTATVFS 1
#define HAVE_GETOPT 1
#define HAVE_GETOPT_LONG 1
#define HAVE_GETPAGESIZE 1
#define HAVE_GETPID 1
#define HAVE_LINK 1
#define HAVE_LOCALTIME_R 1
#define HAVE_LRAND48 1
#define HAVE_LSTAT 1
#define HAVE_MKDTEMP 1
#define HAVE_MKOSTEMP 1
#define HAVE_MKSTEMP 1
#define HAVE_MMAP 1
#define HAVE_RAND 1
#define HAVE_RANDOM 1
#define HAVE_RAND_R 1
#define HAVE_READLINK 1
#define HAVE_STRERROR 1
#define HAVE_STRERROR_R 1
#define HAVE_VPRINTF 1
#define HAVE_VSNPRINTF 1
#define HAVE_VSPRINTF 1

/* Struct members present on both platforms. */
#define HAVE_STRUCT_DIRENT_D_TYPE 1
#define HAVE_STRUCT_STATFS_F_FLAGS 1

/* FreeType 2.14 has all of these. */
#define HAVE_FT_DONE_MM_VAR 1
#define HAVE_FT_GET_BDF_PROPERTY 1
#define HAVE_FT_GET_PS_FONT_INFO 1
#define HAVE_FT_GET_X11_FONT_FORMAT 1
#define HAVE_FT_HAS_PS_GLYPH_NAMES 1

/* Disabled features (value-tested or referenced unconditionally). */
#define USE_ICONV 0
#define GETTEXT_PACKAGE "fontconfig"

/* Platform deltas.  These macros are #ifdef-tested, so they must be left
 * undefined (not defined to 0) where the feature is absent. */
#ifdef __APPLE__
#define HAVE_GETPROGNAME 1
#define HAVE_STRUCT_STATFS_F_FSTYPENAME 1
#else /* Linux/glibc */
#define HAVE_POSIX_FADVISE 1
#define HAVE_RANDOM_R 1
#define HAVE_STRUCT_STAT_ST_MTIM 1
#define HAVE_SYS_STATFS_H 1
#define HAVE_SYS_VFS_H 1
#endif

#include "config-fixups.h"

#endif /* FC_BAZEL_CONFIG_H */
