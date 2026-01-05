/* tclConfig.h.  Generated from tclConfig.h.in by configure.  */
/* ../unix/tclConfig.h.in.  Generated from configure.ac by autoheader.  */


    #ifndef _TCLCONFIG
    #define _TCLCONFIG

/* Is gettimeofday() actually declared in <sys/time.h>? */
/* #undef GETTOD_NOT_DECLARED */

/* Define to 1 if you have the <AvailabilityMacros.h> header file. */
/* #undef HAVE_AVAILABILITYMACROS_H */

/* Define to 1 if the system has the type 'blkcnt_t'. */
#define HAVE_BLKCNT_T 1

/* Defined when compiler supports casting to union type. */
#define HAVE_CAST_TO_UNION 1

/* Define to 1 if you have the 'chflags' function. */
/* #undef HAVE_CHFLAGS */

/* Define to 1 if you have the 'copyfile' function. */
/* #undef HAVE_COPYFILE */

/* Define to 1 if you have the <copyfile.h> header file. */
/* #undef HAVE_COPYFILE_H */

/* Do we have access to Darwin CoreFoundation.framework? */
/* #undef HAVE_COREFOUNDATION */

/* Is the cpuid instruction usable? */
/* #undef HAVE_CPUID */

/* Define to 1 if you have the declaration of 'gethostbyaddr_r', and to 0 if
   you don't. */
#define HAVE_DECL_GETHOSTBYADDR_R 1

/* Define to 1 if you have the declaration of 'gethostbyname_r', and to 0 if
   you don't. */
#define HAVE_DECL_GETHOSTBYNAME_R 1

/* Is 'DIR64' in <sys/types.h>? */
/* #undef HAVE_DIR64 */

/* Define to 1 if you have the 'freeaddrinfo' function. */
#define HAVE_FREEADDRINFO 1

/* Do we have fts functions? */
#define HAVE_FTS 1

/* Define to 1 if you have the 'gai_strerror' function. */
#define HAVE_GAI_STRERROR 1

/* Define to 1 if you have the 'getaddrinfo' function. */
#define HAVE_GETADDRINFO 1

/* Define to 1 if you have the 'getattrlist' function. */
/* #undef HAVE_GETATTRLIST */

/* Define to 1 if you have the 'getcwd' function. */
#define HAVE_GETCWD 1

/* Define to 1 if getgrgid_r is available. */
#define HAVE_GETGRGID_R 1

/* Define to 1 if getgrgid_r takes 4 args. */
/* #undef HAVE_GETGRGID_R_4 */

/* Define to 1 if getgrgid_r takes 5 args. */
#define HAVE_GETGRGID_R_5 1

/* Define to 1 if getgrnam_r is available. */
#define HAVE_GETGRNAM_R 1

/* Define to 1 if getgrnam_r takes 4 args. */
/* #undef HAVE_GETGRNAM_R_4 */

/* Define to 1 if getgrnam_r takes 5 args. */
#define HAVE_GETGRNAM_R_5 1

/* Define to 1 if gethostbyaddr_r is available. */
#define HAVE_GETHOSTBYADDR_R 1

/* Define to 1 if gethostbyaddr_r takes 7 args. */
/* #undef HAVE_GETHOSTBYADDR_R_7 */

/* Define to 1 if gethostbyaddr_r takes 8 args. */
#define HAVE_GETHOSTBYADDR_R_8 1

/* Define to 1 if gethostbyname_r is available. */
#define HAVE_GETHOSTBYNAME_R 1

/* Define to 1 if gethostbyname_r takes 3 args. */
/* #undef HAVE_GETHOSTBYNAME_R_3 */

/* Define to 1 if gethostbyname_r takes 5 args. */
/* #undef HAVE_GETHOSTBYNAME_R_5 */

/* Define to 1 if gethostbyname_r takes 6 args. */
#define HAVE_GETHOSTBYNAME_R_6 1

/* Define to 1 if you have the 'getnameinfo' function. */
#define HAVE_GETNAMEINFO 1

/* Define to 1 if getpwnam_r is available. */
#define HAVE_GETPWNAM_R 1

/* Define to 1 if getpwnam_r takes 4 args. */
/* #undef HAVE_GETPWNAM_R_4 */

/* Define to 1 if getpwnam_r takes 5 args. */
#define HAVE_GETPWNAM_R_5 1

/* Define to 1 if getpwuid_r is available. */
#define HAVE_GETPWUID_R 1

/* Define to 1 if getpwuid_r takes 4 args. */
/* #undef HAVE_GETPWUID_R_4 */

/* Define to 1 if getpwuid_r takes 5 args. */
#define HAVE_GETPWUID_R_5 1

/* Define to 1 if you have the 'gmtime_r' function. */
#define HAVE_GMTIME_R 1

/* Compiler support for module scope symbols */
#define HAVE_HIDDEN 1

/* Do we have the intptr_t type? */
#define HAVE_INTPTR_T 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Do we have nl_langinfo()? */
#define HAVE_LANGINFO 1

/* Define to 1 if you have the <libkern/OSAtomic.h> header file. */
/* #undef HAVE_LIBKERN_OSATOMIC_H */

/* Define to 1 if you have the 'localtime_r' function. */
#define HAVE_LOCALTIME_R 1

/* Define to 1 if you have the 'lseek64' function. */
/* #undef HAVE_LSEEK64 */

/* Define to 1 if you have the 'mkstemp' function. */
#define HAVE_MKSTEMP 1

/* Define to 1 if you have the 'mkstemps' function. */
#define HAVE_MKSTEMPS 1

/* Define to 1 if you have the 'mktime' function. */
#define HAVE_MKTIME 1

/* Do we have MT-safe gethostbyaddr() ? */
/* #undef HAVE_MTSAFE_GETHOSTBYADDR */

/* Do we have MT-safe gethostbyname() ? */
/* #undef HAVE_MTSAFE_GETHOSTBYNAME */

/* Do we have <net/errno.h>? */
/* #undef HAVE_NET_ERRNO_H */

/* Define to 1 if you have the 'open64' function. */
/* #undef HAVE_OPEN64 */

/* Define to 1 if you have the 'opendir' function. */
#define HAVE_OPENDIR 1

/* Define to 1 if you have the 'OSSpinLockLock' function. */
/* #undef HAVE_OSSPINLOCKLOCK */

/* Define to 1 if you have the 'posix_spawnattr_setflags' function. */
#define HAVE_POSIX_SPAWNATTR_SETFLAGS 1

/* Define to 1 if you have the 'posix_spawnp' function. */
#define HAVE_POSIX_SPAWNP 1

/* Define to 1 if you have the 'posix_spawn_file_actions_adddup2' function. */
#define HAVE_POSIX_SPAWN_FILE_ACTIONS_ADDDUP2 1

/* Define to 1 if you have the 'pthread_atfork' function. */
#define HAVE_PTHREAD_ATFORK 1

/* Define to 1 if you have the 'pthread_attr_setstacksize' function. */
#define HAVE_PTHREAD_ATTR_SETSTACKSIZE 1

/* Does putenv() copy strings or incorporate them by reference? */
/* #undef HAVE_PUTENV_THAT_COPIES */

/* Are characters signed? */
#define HAVE_SIGNED_CHAR 1

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

/* Define to 1 if you have the 'strtol' function. */
#define HAVE_STRTOL 1

/* Define to 1 if the system has the type 'struct addrinfo'. */
#define HAVE_STRUCT_ADDRINFO 1

/* Is 'struct dirent64' in <sys/types.h>? */
/* #undef HAVE_STRUCT_DIRENT64 */

/* Define to 1 if the system has the type 'struct in6_addr'. */
#define HAVE_STRUCT_IN6_ADDR 1

/* Define to 1 if the system has the type 'struct sockaddr_in6'. */
#define HAVE_STRUCT_SOCKADDR_IN6 1

/* Define to 1 if the system has the type 'struct sockaddr_storage'. */
#define HAVE_STRUCT_SOCKADDR_STORAGE 1

/* Is 'struct stat64' in <sys/stat.h>? */
/* #undef HAVE_STRUCT_STAT64 */

/* Define to 1 if 'st_blksize' is a member of 'struct stat'. */
#define HAVE_STRUCT_STAT_ST_BLKSIZE 1

/* Define to 1 if 'st_blocks' is a member of 'struct stat'. */
#define HAVE_STRUCT_STAT_ST_BLOCKS 1

/* Define to 1 if you have the <sys/filio.h> header file. */
/* #undef HAVE_SYS_FILIO_H */

/* Define to 1 if you have the <sys/ioctl.h> header file. */
#define HAVE_SYS_IOCTL_H 1

/* Define to 1 if you have the <sys/modem.h> header file. */
/* #undef HAVE_SYS_MODEM_H */

/* Define to 1 if you have the <sys/param.h> header file. */
#define HAVE_SYS_PARAM_H 1

/* Should we include <sys/select.h>? */
/* #undef HAVE_SYS_SELECT_H */

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/time.h> header file. */
#define HAVE_SYS_TIME_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <termios.h> header file. */
#define HAVE_TERMIOS_H 1

/* Should we use the global timezone variable? */
#define HAVE_TIMEZONE_VAR 1

/* Should we use the tm_gmtoff field of struct tm? */
#define HAVE_TM_GMTOFF 1

/* Should we use the tm_tzadj field of struct tm? */
/* #undef HAVE_TM_TZADJ */

/* Is off64_t in <sys/types.h>? */
/* #undef HAVE_TYPE_OFF64_T */

/* Do we have the uintptr_t type? */
#define HAVE_UINTPTR_T 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if you have the 'vfork' function. */
#define HAVE_VFORK 1

/* Define to 1 if you have the 'waitpid' function. */
#define HAVE_WAITPID 1

/* Is weak import available? */
/* #undef HAVE_WEAK_IMPORT */

/* Is there an installed zlib? */
#define HAVE_ZLIB 1

/* Is this a Mac I see before me? */
/* #undef MAC_OSX_TCL */

/* No Compiler support for module scope symbols */
#define MODULE_SCOPE extern __attribute__((__visibility__("hidden")))

/* Default libtommath precision. */
#define MP_PREC 4

/* Is no debugging enabled? */
#define NDEBUG 1

/* Use compat implementation of getaddrinfo() and friends */
/* #undef NEED_FAKE_RFC2553 */

/* Is Darwin CoreFoundation unavailable for 64-bit? */
/* #undef NO_COREFOUNDATION_64 */

/* Do we have <dirent.h>? */
/* #undef NO_DIRENT_H */

/* Do we have <dlfcn.h>? */
/* #undef NO_DLFCN_H */

/* Do we have fd_set? */
/* #undef NO_FD_SET */

/* Do we have <float.h>? */
/* #undef NO_FLOAT_H */

/* Do we have fork() */
/* #undef NO_FORK */

/* Do we have fstatfs()? */
/* #undef NO_FSTATFS */

/* Do we have gettimeofday()? */
/* #undef NO_GETTOD */

/* Do we have getwd() */
/* #undef NO_GETWD */

/* Do we have a usable 'isnan'? */
/* #undef NO_ISNAN */

/* Do we have memmove()? */
/* #undef NO_MEMMOVE */

/* Do we have mknod() */
/* #undef NO_MKNOD */

/* Do we have realpath() */
/* #undef NO_REALPATH */

/* Do we have <stdlib.h>? */
/* #undef NO_STDLIB_H */

/* Do we have strerror() */
/* #undef NO_STRERROR */

/* Do we have <string.h>? */
/* #undef NO_STRING_H */

/* Do we have <sys/wait.h>? */
/* #undef NO_SYS_WAIT_H */

/* Do we have tcdrain() */
/* #undef NO_TCDRAIN */

/* Do we have uname() */
/* #undef NO_UNAME */

/* Do we have a usable 'union wait'? */
#define NO_UNION_WAIT 1

/* Do we have <values.h>? */
/* #undef NO_VALUES_H */

/* Do we have wait3() */
/* #undef NO_WAIT3 */

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT ""

/* Define to the full name of this package. */
#define PACKAGE_NAME "tcl"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "tcl 8.6"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "tcl"

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION "8.6"

/* Is this a static build? */
/* #undef STATIC_BUILD */

/* Define to 1 if all of the C89 standard headers exist (not just the ones
   required in a freestanding environment). This macro is provided for
   backward compatibility; new code need not use it. */
#define STDC_HEADERS 1

/* What encoding should be used for embedded configuration info? */
#define TCL_CFGVAL_ENCODING "iso8859-1"

/* Is this a 64-bit build? */
/* #undef TCL_CFG_DO64BIT */

/* Is this an optimized build? */
#define TCL_CFG_OPTIMIZED 1

/* Is bytecode debugging enabled? */
/* #undef TCL_COMPILE_DEBUG */

/* Are bytecode statistics enabled? */
/* #undef TCL_COMPILE_STATS */

/* Are we to override what our default encoding is? */
/* #undef TCL_DEFAULT_ENCODING */

/* Is Tcl built as a framework? */
/* #undef TCL_FRAMEWORK */

/* Can this platform load code from memory? */
/* #undef TCL_LOAD_FROM_MEMORY */

/* Is memory debugging enabled? */
/* #undef TCL_MEM_DEBUG */

/* What is the default extension for shared libraries? */
#define TCL_SHLIB_EXT ".so"

/* Are we building with threads enabled? */
#define TCL_THREADS 1

/* Do we allow unloading of shared libraries? */
#define TCL_UNLOAD_DLLS 1

/* Does this platform have wide high-resolution clicks? */
/* #undef TCL_WIDE_CLICKS */

/* Are wide integers to be implemented with C 'long's? */
#define TCL_WIDE_INT_IS_LONG 1

/* What type should be used to define wide integers? */
/* #undef TCL_WIDE_INT_TYPE */

/* Define to 1 if you can safely include both <sys/time.h> and <time.h>. This
   macro is obsolete. */
#define TIME_WITH_SYS_TIME 1

/* Is getcwd Posix-compliant? */
/* #undef USEGETWD */

/* May we include <dirent2.h>? */
/* #undef USE_DIRENT2_H */

/* Are we building with DTrace support? */
/* #undef USE_DTRACE */

/* Should we use FIONBIO? */
/* #undef USE_FIONBIO */

/* Do we want to use the threaded memory allocator? */
#define USE_THREAD_ALLOC 1

/* Define WORDS_BIGENDIAN to 1 if your processor stores words with the most
   significant byte first (like Motorola and SPARC, unlike Intel). */
#if defined AC_APPLE_UNIVERSAL_BUILD
# if defined __BIG_ENDIAN__
#  define WORDS_BIGENDIAN 1
# endif
#else
# ifndef WORDS_BIGENDIAN
/* #  undef WORDS_BIGENDIAN */
# endif
#endif

/* Are Darwin SUSv3 extensions available? */
/* #undef _DARWIN_C_SOURCE */

/* Add the _ISOC99_SOURCE flag when building */
/* #undef _ISOC99_SOURCE */

/* Add the _LARGEFILE64_SOURCE flag when building */
#define _LARGEFILE64_SOURCE 1

/* # needed in sys/socket.h Should OS/390 do the right thing with sockets? */
/* #undef _OE_SOCKETS */

/* Do we really want to follow the standard? Yes we do! */
/* #undef _POSIX_PTHREAD_SEMANTICS */

/* Do we want the reentrant OS API? */
#define _REENTRANT 1

/* Do we want the thread-safe OS API? */
#define _THREAD_SAFE 1

/* Do we want to use the XOPEN network library? */
/* #undef _XOPEN_SOURCE */

/* Do we want to use the XOPEN network library? */
/* #undef _XOPEN_SOURCE_EXTENDED */

/* Define to 1 if type 'char' is unsigned and your compiler does not
   predefine this macro.  */
#ifndef __CHAR_UNSIGNED__
# define __CHAR_UNSIGNED__ 1
#endif

/* Define as 'int' if <sys/types.h> doesn't define. */
/* #undef gid_t */

/* Define to '__inline__' or '__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
/* #undef inline */
#endif

/* Signed integer type wide enough to hold a pointer. */
/* #undef intptr_t */

/* Define to 'int' if <sys/types.h> does not define. */
/* #undef mode_t */

/* Define as a signed integer type capable of holding a process identifier. */
/* #undef pid_t */

/* Define as 'unsigned int' if <stddef.h> doesn't define. */
/* #undef size_t */

/* Define as int if socklen_t is not available */
/* #undef socklen_t */

/* Define as 'int' if <sys/types.h> doesn't define. */
/* #undef uid_t */

/* Unsigned integer type wide enough to hold a pointer. */
/* #undef uintptr_t */


    /* Undef unused package specific autoheader defines so that we can
     * include both tclConfig.h and tkConfig.h at the same time: */
    /* override */ #undef PACKAGE_NAME
    /* override */ #undef PACKAGE_TARNAME
    /* override */ #undef PACKAGE_VERSION
    /* override */ #undef PACKAGE_STRING
    #endif /* _TCLCONFIG */
