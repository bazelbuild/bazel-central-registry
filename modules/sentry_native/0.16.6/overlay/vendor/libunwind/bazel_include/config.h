/* Linux configuration for the vendored libunwind 1.8.3 Bazel target.
 *
 * Header presence is evaluated by the declared C/C++ sysroot. Optional
 * configure probes are kept conservative so the same overlay works with the
 * supported glibc and musl LLVM toolchains.
 */

#if defined(__has_include)
#    if __has_include(<asm/ptrace.h>)
#        define HAVE_ASM_PTRACE_H 1
#    endif
#    if __has_include(<byteswap.h>)
#        define HAVE_BYTESWAP_H 1
#    endif
#    if __has_include(<elf.h>)
#        define HAVE_ELF_H 1
#    endif
#    if __has_include(<endian.h>)
#        define HAVE_ENDIAN_H 1
#    endif
#    if __has_include(<link.h>)
#        define HAVE_LINK_H 1
#    endif
#    if __has_include(<signal.h>)
#        define HAVE_SIGNAL_H 1
#    endif
#    if __has_include(<sys/param.h>)
#        define HAVE_SYS_PARAM_H 1
#    endif
#    if __has_include(<sys/procfs.h>)
#        define HAVE_SYS_PROCFS_H 1
#    endif
#    if __has_include(<sys/ptrace.h>)
#        define HAVE_SYS_PTRACE_H 1
#    endif
#    if __has_include(<sys/stat.h>)
#        define HAVE_SYS_STAT_H 1
#    endif
#    if __has_include(<sys/syscall.h>)
#        define HAVE_SYS_SYSCALL_H 1
#    endif
#    if __has_include(<sys/types.h>)
#        define HAVE_SYS_TYPES_H 1
#    endif
#endif

#define HAVE_DECL_PTRACE_CONT 1
#define HAVE_DECL_PTRACE_POKEDATA 1
#define HAVE_DECL_PTRACE_POKEUSER 1
#define HAVE_DECL_PTRACE_SETREGSET 1
#define HAVE_DECL_PTRACE_SINGLESTEP 1
#define HAVE_DECL_PTRACE_SYSCALL 1
#define HAVE_DECL_PTRACE_TRACEME 1

#define HAVE_DECL_PT_CONTINUE 0
#define HAVE_DECL_PT_GETFPREGS 0
#define HAVE_DECL_PT_GETREGS 0
#define HAVE_DECL_PT_IO 0
#define HAVE_DECL_PT_STEP 0
#define HAVE_DECL_PT_SYSCALL 0
#define HAVE_DECL_PT_TRACE_ME 0

#define HAVE_DL_ITERATE_PHDR 1
#define HAVE_MINCORE 1
#define HAVE_PIPE2 1
#define HAVE_SIGALTSTACK 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_UNISTD_H 1

#define PACKAGE_STRING "libunwind 1.8.3"
#define PACKAGE_BUGREPORT "N/A"
#define STDC_HEADERS 1
#define SIZEOF_OFF_T 8
