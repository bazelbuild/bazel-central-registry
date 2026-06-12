//
//  config.h - hand maintained configuration header for the Bazel build.
//
//  The autotools build generates this file with `configure`.  For the native
//  Bazel build we provide a fixed configuration targeting Linux on a glibc
//  system (x86-64 or aarch64).  Only the definitions that the autotools build
//  would emit on such a platform are present; anything probed by configure and
//  absent here is intentionally left undefined so the source falls back to its
//  portable code paths.
//
//  Keep this in sync with configure.ac when the upstream configuration logic
//  changes.
//

#ifndef NVC_CONFIG_H
#define NVC_CONFIG_H

// Package identification (from AC_INIT in configure.ac).
#define PACKAGE         "nvc"
#define PACKAGE_NAME    "nvc"
#define PACKAGE_TARNAME "nvc"
#define PACKAGE_VERSION "1.22-devel"
#define PACKAGE_STRING  "nvc 1.22-devel"
#define VERSION         "1.22-devel"
#define PACKAGE_BUGREPORT "https://github.com/nickg/nvc/issues"
#define PACKAGE_URL     "https://www.nickg.me.uk/nvc/"

// Installation directories.  These are only used as a fall-back when locating
// the standard libraries; the Bazel build points NVC at its runfiles using the
// NVC_LIBPATH environment variable instead.
#define PREFIX          "/usr/local"
#define LIBDIR          "/usr/local/lib/nvc"
#define LIBEXECDIR      "/usr/local/libexec/nvc"
#define DATADIR         "/usr/local/share/nvc"

// Platform conventions.
#define DIR_SEP         "/"
#define PATH_SEP        ":"
#define EXEEXT          ""
#define DLL_EXT         "so"
#define SH_PATH         "/bin/sh"
#define DIFF_PATH       "/usr/bin/diff"
#define TARGET_SYSTEM   "x86_64-pc-linux-gnu"

// Enable the default library search paths (HOME/.nvc/lib, $NVC_LIBPATH and the
// compiled-in LIBDIR).  Required for NVC_LIBPATH to be honoured.
#define ENABLE_DEFAULT_PATHS 1

// FST waveform writer: collapse duplicate value changes.
#define FST_REMOVE_DUPLICATE_VC 1

// Disable the extra development-only debugging checks (release build).
#define NDEBUG 1

// System headers available on Linux/glibc.
#define HAVE_SYS_PTRACE_H 1
#define HAVE_SYS_PRCTL_H 1
#define HAVE_UCONTEXT_H 1
#define HAVE_SYS_UCONTEXT_H 1
#define HAVE_STDIO_EXT_H 1

// Library functions available on glibc.
#define HAVE_MEMMEM 1
#define HAVE_STRCASESTR 1
#define HAVE_GETLINE 1
#define HAVE_STRCHRNUL 1
#define HAVE_STRNDUP 1
#define HAVE_FSEEKO 1
#define HAVE_FTELLO 1
#define HAVE_GETCONTEXT 1
#define HAVE___FPURGE 1
#define HAVE_GETTID 1
#define HAVE_POPEN 1

// struct stat high resolution timestamps (Linux flavour).
#define HAVE_STRUCT_STAT_ST_MTIM_TV_NSEC 1

// Compiler features supported by GCC and Clang.
#define HAVE_FUNC_ATTRIBUTE_RETURNS_NONNULL 1
#define HAVE___BUILTIN_SETJMP 1

// POSIX threads.
#define HAVE_PTHREAD 1

// SIMD acceleration.  The vectorised code paths are compiled with per-function
// `__attribute__((target(...)))` and guarded at runtime with
// __builtin_cpu_supports(), so enabling them does not require global -m flags
// and remains safe on CPUs that lack the extensions (the scalar paths are used
// instead).  The architecture is detected the same way as in src/util.h.
#if defined(__x86_64__)
#define HAVE_SSE41 1
#define HAVE_AVX2 1
#define HAVE_SSE_SHA 1
#endif

#endif  // NVC_CONFIG_H
