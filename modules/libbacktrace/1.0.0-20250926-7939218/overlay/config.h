// I.e. glibc needs this for dl_iterate_phdr
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <stdint.h>

#if UINTPTR_MAX == 0xffffffff
#define BACKTRACE_ELF_SIZE 32
#ifdef __i386__
#define HAVE_ATOMIC_FUNCTIONS 1
#define HAVE_SYNC_FUNCTIONS 1
#endif
#else
#if UINTPTR_MAX != 0xffffffffffffffffULL
#error bad elf word size!?
#endif
#define BACKTRACE_ELF_SIZE 64
#define HAVE_ATOMIC_FUNCTIONS 1
#define HAVE_SYNC_FUNCTIONS 1
#endif

#if defined __ELF__
#define HAVE_DL_ITERATE_PHDR 1
#define HAVE_LINK_H 1

// FreeBSD. We also assume it has modern enough GCC-compatible compiler
#if defined __has_include
#if __has_include(<sys/sysctl.h>)
#if defined KERN_PROC
#define HAVE_KERN_PROC 1
#endif
#if defined KERN_PROC_ARGS
#define HAVE_KERN_PROC_ARGS 1
#endif
#endif
#endif

#elif defined __MACH__
#define HAVE_MACH_O_DYLD_H
#else
#error This code is only prepared to deal with ELF systems or OSX (mach-o)
#endif

#define HAVE_FCNTL 1
#define HAVE_LSTAT 1
#define HAVE_MEMORY_H 1
#define HAVE_READLINK 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_DECL_GETPAGESIZE 1
#define HAVE_DECL_STRNLEN 1
#define HAVE_DECL__PGMPTR 0
#define HAVE_DLFCN_H 1
#define HAVE_GETIPINFO 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_MMAN_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1



