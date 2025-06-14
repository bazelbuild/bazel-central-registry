/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

/* extra */
#define _PATH_MODDIR "plugins"

/* Defined if debug mode is enabled (its easier to check). */
/* #undef DEBUG */

/* Defined if debugless mode is enabled. */
/* #undef DEBUGLESS */

/* Indicator that GnuTLS is present */
/* #undef ENABLE_GNUTLS */

/* Indicator that IMDIAG is present */
/* #undef ENABLE_IMDIAG */

/* Indicator that we need to build a dummy imkafka module */
/* #undef ENABLE_IMKAFKA_DUMMY */

/* Enable epoll mode for the imtcp input module */
#define ENABLE_IMTCP_EPOLL 1

/* Indicator that libcap-ng is present */
/* #undef ENABLE_LIBCAPNG */

/* Indicator that libcap-ng is present */
/* #undef ENABLE_LIBCAPNG_PRESENT */

/* Indicator that LIBGCRYPT is present */
/* #undef ENABLE_LIBGCRYPT */

/* Indicator that we need to build a dummy module */
/* #undef ENABLE_MMBDLOOKUP_DUMMY */

/* Indicator that we need to build a dummy omkafka module */
/* #undef ENABLE_OMKAFKA_DUMMY */

/* Indicator that openssl is present */
/* #undef ENABLE_OPENSSL */

/* Indicator that openssl(EVP_CIPHER_get_block_size) is present */
/* #undef ENABLE_OPENSSL_CRYPTO_PROVIDER */

/* Indicator that RELP is present */
/* #undef ENABLE_RELP */

/* Regular expressions support enabled. */
#define FEATURE_REGEXP 1

/* Define to 1 if you have the `alarm' function. */
#define HAVE_ALARM 1

/* Define to 1 if you have the <apr_base64.h> header file. */
/* #undef HAVE_APR_BASE64_H */

/* Define to 1 if you have the <apr_md5.h> header file. */
/* #undef HAVE_APR_MD5_H */

/* Define to 1 if you have the <arpa/nameser.h> header file. */
#define HAVE_ARPA_NAMESER_H 1

/* Define to 1 if you have the `asprintf' function. */
#define HAVE_ASPRINTF 1

/* Define if compiler provides atomic builtins */
#define HAVE_ATOMIC_BUILTINS 1

/* Define if compiler provides 64 bit atomic builtins */
#define HAVE_ATOMIC_BUILTINS64 1

/* Define to 1 if you have the `basename' function. */
#define HAVE_BASENAME 1

/* Define to 1 if compiler supports __builtin_expect */
#define HAVE_BUILTIN_EXPECT 1

/* Define to 1 if your system has a working `chown' function. */
#define HAVE_CHOWN 1

/* Define to 1 if you have the <civetweb.h> header file. */
/* #undef HAVE_CIVETWEB_H */

/* Define to 1 if you have the `clock_gettime' function. */
#define HAVE_CLOCK_GETTIME 1

/* Define to 1 if you have the `close_range' function. */
#define HAVE_CLOSE_RANGE 1

/* Define to 1 if you have the <curl/curl.h> header file. */
/* #undef HAVE_CURL_CURL_H */

/* Define to 1 if you have the <dbi/dbi.h> header file. */
/* #undef HAVE_DBI_DBI_H */

/* Define to 1 if libdbi supports the new plugin-safe interface */
/* #undef HAVE_DBI_R */

/* Define to 1 if libdbi supports transactions */
/* #undef HAVE_DBI_TXSUPP */

/* Define to 1 if you have the declaration of `strerror_r', and to 0 if you
   don't. */
#define HAVE_DECL_STRERROR_R 1

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you don't have `vprintf' but do have `_doprnt.' */
/* #undef HAVE_DOPRNT */

/* Define to 1 if you have the `epoll_create' function. */
#define HAVE_EPOLL_CREATE 1

/* Define to 1 if you have the `epoll_create1' function. */
#define HAVE_EPOLL_CREATE1 1

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if you have the `fdatasync' function. */
#define HAVE_FDATASYNC 1

/* Define to 1 if you have the `flock' function. */
#define HAVE_FLOCK 1

/* Define to 1 if you have the `fork' function. */
#define HAVE_FORK 1

/* Define to 1 if you have the `gethostbyname' function. */
#define HAVE_GETHOSTBYNAME 1

/* Define to 1 if you have the `gethostname' function. */
#define HAVE_GETHOSTNAME 1

/* set define */
#define HAVE_GETIFADDRS 1

/* Define to 1 if you have the `getline' function. */
#define HAVE_GETLINE 1

/* Define to 1 if you have the <getopt.h> header file. */
#define HAVE_GETOPT_H 1

/* Define to 1 if you have the `gettimeofday' function. */
#define HAVE_GETTIMEOFDAY 1

/* set define */
#define HAVE_GLOB_NOMAGIC 1

/* Define to 1 if you have the `gnutls_certificate_set_retrieve_function'
   function. */
/* #undef HAVE_GNUTLS_CERTIFICATE_SET_RETRIEVE_FUNCTION */

/* Define to 1 if you have the `gnutls_certificate_type_set_priority'
   function. */
/* #undef HAVE_GNUTLS_CERTIFICATE_TYPE_SET_PRIORITY */

/* Define to 1 if you have the <grok.h> header file. */
/* #undef HAVE_GROK_H */

/* Define to 1 if you have the <hadoop/hdfs.h> header file. */
/* #undef HAVE_HADOOP_HDFS_H */

/* Define to 1 if you have the <hdfs.h> header file. */
/* #undef HAVE_HDFS_H */

/* Define to 1 if you have the `inotify_init' function. */
#define HAVE_INOTIFY_INIT 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* jemalloc support is integrated. */
/* #undef HAVE_JEMALLOC */

/* Define to 1 if you have the <libgen.h> header file. */
#define HAVE_LIBGEN_H 1

/* Define to 1 if liblogging-stdlog is available. */
/* #undef HAVE_LIBLOGGING_STDLOG */

/* Define to 1 if you have the `mysqlclient' library (-lmysqlclient). */
/* #undef HAVE_LIBMYSQLCLIENT */

/* Define to 1 if you have the <libnet.h> header file. */
/* #undef HAVE_LIBNET_H */

/* Define to 1 if you have the <librdkafka/rdkafka.h> header file. */
/* #undef HAVE_LIBRDKAFKA_RDKAFKA_H */

/* libsystemd present */
/* #undef HAVE_LIBSYSTEMD */

/* Define to 1 if you have the <linux/close_range.h> header file. */
#define HAVE_LINUX_CLOSE_RANGE_H 1

/* Define if ln_loadSamplesFromString exists. */
/* #undef HAVE_LOADSAMPLESFROMSTRING */

/* Define to 1 if you have the <locale.h> header file. */
#define HAVE_LOCALE_H 1

/* Define to 1 if you have the `localtime_r' function. */
#define HAVE_LOCALTIME_R 1

/* Define to 1 if you have the `lseek64' function. */
#define HAVE_LSEEK64 1

/* Define to 1 if you have the <malloc.h> header file. */
#define HAVE_MALLOC_H 1

/* Define to 1 if you have the `malloc_trim' function. */
#define HAVE_MALLOC_TRIM 1

/* Define to 1 if you have the <maxminddb.h> header file. */
/* #undef HAVE_MAXMINDDB_H */

/* Define to 1 if you have the `memset' function. */
#define HAVE_MEMSET 1

/* Define to 1 if you have the <minix/config.h> header file. */
/* #undef HAVE_MINIX_CONFIG_H */

/* Define to 1 if you have the `mkdir' function. */
#define HAVE_MKDIR 1

/* Define to 1 if you have the `mongoc_client_set_ssl_opts' function. */
/* #undef HAVE_MONGOC_CLIENT_SET_SSL_OPTS */

/* mysql_library_init available */
/* #undef HAVE_MYSQL_LIBRARY_INIT */

/* Define to 1 if you have the <netdb.h> header file. */
#define HAVE_NETDB_H 1

/* Define to 1 if you have the <netinet/in.h> header file. */
#define HAVE_NETINET_IN_H 1

/* Define to 1 if you have the <net-snmp/net-snmp-config.h> header file. */
/* #undef HAVE_NET_SNMP_NET_SNMP_CONFIG_H */

/* Define to 1 if the system has the type `off64_t'. */
#define HAVE_OFF64_T 1

/* Define to 1 if you have the <paths.h> header file. */
#define HAVE_PATHS_H 1

/* Define to 1 if you have the <pcap.h> header file. */
/* #undef HAVE_PCAP_H */

/* PGsslInUse function available */
/* #undef HAVE_PGSSLINUSE */

/* Define to 1 if you have the `port_create' function. */
/* #undef HAVE_PORT_CREATE */

/* Enable FEN support for imfile */
/* #undef HAVE_PORT_SOURCE_FILE */

/* Define to 1 if you have the `prctl' function. */
#define HAVE_PRCTL 1

/* Define to 1 if you have the <protocol.h> header file. */
/* #undef HAVE_PROTOCOL_H */

/* Define to 1 if you have the <pthread.h> header file. */
#define HAVE_PTHREAD_H 1

/* Set-kind available for rwlock attr. */
#define HAVE_PTHREAD_RWLOCKATTR_SETKIND_NP 1

/* Can set thread-name. */
#define HAVE_PTHREAD_SETNAME_NP 1

/* Can set thread scheduling parameters */
#define HAVE_PTHREAD_SETSCHEDPARAM 1

/* Define to 1 if you have the `recvmmsg' function. */
#define HAVE_RECVMMSG 1

/* Define to 1 if you have the `regcomp' function. */
#define HAVE_REGCOMP 1

/* Define if relpSrvSetTlsConfigCmd exists. */
/* #undef HAVE_RELPENGINESETTLSCFGCMD */

/* Define if relpEngineSetTLSLibByName exists. */
/* #undef HAVE_RELPENGINESETTLSLIBBYNAME */

/* Define if relpSrvSetLstnAddr exists. */
/* #undef HAVE_RELPSRVSETLSTNADDR */

/* Define if relpSrvSetOversizeMode exists. */
/* #undef HAVE_RELPSRVSETOVERSIZEMODE */

/* Define to 1 if you have the <resolv.h> header file. */
#define HAVE_RESOLV_H 1

/* Define to 1 if you have the `sched_get_priority_max' function. */
#define HAVE_SCHED_GET_PRIORITY_MAX 1

/* Define to 1 if you have the <sched.h> header file. */
#define HAVE_SCHED_H 1

/* set define */
#define HAVE_SCM_CREDENTIALS 1

/* Define to 1 if you have the `select' function. */
#define HAVE_SELECT 1

/* Define to 1 if you have the <semaphore.h> header file. */
#define HAVE_SEMAPHORE_H 1

/* Define if setns exists. */
#define HAVE_SETNS 1

/* Define to 1 if you have the `setsid' function. */
#define HAVE_SETSID 1

/* Define to 1 if you have the `socket' function. */
#define HAVE_SOCKET 1

/* set define */
#define HAVE_SO_TIMESTAMP 1

/* Define to 1 if `stat' has the bug that it succeeds when given the
   zero-length file name argument. */
/* #undef HAVE_STAT_EMPTY_STRING_BUG */

/* Define to 1 if you have the <stddef.h> header file. */
#define HAVE_STDDEF_H 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdio.h> header file. */
#define HAVE_STDIO_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the `strcasecmp' function. */
#define HAVE_STRCASECMP 1

/* Define to 1 if you have the `strchr' function. */
#define HAVE_STRCHR 1

/* Define to 1 if you have the `strdup' function. */
#define HAVE_STRDUP 1

/* Define to 1 if you have the `strerror' function. */
#define HAVE_STRERROR 1

/* Define if you have `strerror_r'. */
#define HAVE_STRERROR_R 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the `strndup' function. */
#define HAVE_STRNDUP 1

/* Define to 1 if you have the `strnlen' function. */
#define HAVE_STRNLEN 1

/* Define to 1 if you have the `strrchr' function. */
#define HAVE_STRRCHR 1

/* Define to 1 if you have the `strstr' function. */
#define HAVE_STRSTR 1

/* Define to 1 if you have the `strtol' function. */
#define HAVE_STRTOL 1

/* Define to 1 if you have the `strtoul' function. */
#define HAVE_STRTOUL 1

/* Define to 1 if `sa_len' is a member of `struct sockaddr'. */
/* #undef HAVE_STRUCT_SOCKADDR_SA_LEN */

/* Define to 1 if you have the `syscall' function. */
#define HAVE_SYSCALL 1

/* set define */
#define HAVE_SYSINFO_UPTIME 1

/* Define to 1 if you have the <sys/epoll.h> header file. */
#define HAVE_SYS_EPOLL_H 1

/* Define to 1 if you have the <sys/file.h> header file. */
#define HAVE_SYS_FILE_H 1

/* Define to 1 if you have the <sys/inotify.h> header file. */
#define HAVE_SYS_INOTIFY_H 1

/* Define to 1 if you have the <sys/ioctl.h> header file. */
#define HAVE_SYS_IOCTL_H 1

/* Define to 1 if you have the <sys/param.h> header file. */
#define HAVE_SYS_PARAM_H 1

/* Define to 1 if you have the <sys/prctl.h> header file. */
#define HAVE_SYS_PRCTL_H 1

/* Define to 1 if you have the <sys/select.h> header file. */
#define HAVE_SYS_SELECT_H 1

/* Define to 1 if you have the <sys/socket.h> header file. */
#define HAVE_SYS_SOCKET_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/syscall.h> header file. */
#define HAVE_SYS_SYSCALL_H 1

/* Define to 1 if you have the <sys/time.h> header file. */
#define HAVE_SYS_TIME_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have <sys/wait.h> that is POSIX.1 compatible. */
#define HAVE_SYS_WAIT_H 1

/* set define */
#define HAVE_SYS_gettid 1

/* Define to 1 if you have the `ttyname_r' function. */
#define HAVE_TTYNAME_R 1

/* Define to 1 if you have the `uname' function. */
#define HAVE_UNAME 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if you have the <utmpx.h> header file. */
#define HAVE_UTMPX_H 1

/* Define to 1 if you have the <utmp.h> header file. */
#define HAVE_UTMP_H 1

/* Define to 1 if you have the `vfork' function. */
#define HAVE_VFORK 1

/* Define to 1 if you have the <vfork.h> header file. */
/* #undef HAVE_VFORK_H */

/* Define to 1 if you have the `vprintf' function. */
#define HAVE_VPRINTF 1

/* Define to 1 if you have the <wchar.h> header file. */
#define HAVE_WCHAR_H 1

/* Define to 1 if `fork' works. */
#define HAVE_WORKING_FORK 1

/* Define to 1 if `vfork' works. */
#define HAVE_WORKING_VFORK 1

/* the host environment, can be queried via a system variable */
#define HOSTENV "x86_64-pc-linux-gnu"

/* Define to 1 if `lstat' dereferences a symlink specified with a trailing
   slash. */
#define LSTAT_FOLLOWS_SLASHED_SYMLINK 1

/* Define to the sub-directory where libtool stores uninstalled libraries. */
#define LT_OBJDIR ".libs/"

/* Define with a value if your <sys/param.h> does not define MAXHOSTNAMELEN */
/* #undef MAXHOSTNAMELEN */

/* replacement for missing PATH_MAX */
/* #undef MAXPATHLEN */

/* Defined if debug mode is disabled. */
#define NDEBUG 1

/* new systemd present */
/* #undef NEW_JOURNAL */

/* Define if ln_loadSamplesFromString does not exist. */
/* #undef NO_LOADSAMPLESFROMSTRING */

/* Indicator for a AIX OS */
/* #undef OS_AIX */

/* Indicator for APPLE OS */
/* #undef OS_APPLE */

/* Indicator for a BSD OS */
/* #undef OS_BSD */

/* Indicator for a Linux OS */
#define OS_LINUX 1

/* Indicator for a Solaris OS */
/* #undef OS_SOLARIS */

/* Name of package */
#define PACKAGE "rsyslog"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "rsyslog@lists.adiscon.com"

/* Define to the full name of this package. */
#define PACKAGE_NAME "rsyslog"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "rsyslog 8.2504.0"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "rsyslog"

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION "8.2504.0"

/* "Configuration file path (default : /etc/rsyslog.conf)" */
/* #undef PATH_CONFFILE */

/* replacement for missing PATH_MAX */
/* #undef PATH_MAX */

/* "Pid file path (default : /var/run/rsyslogd.pid)" */
/* #undef PATH_PIDFILE */

/* platform id for display purposes */
#define PLATFORM_ID "x86_64-pc-linux-gnu"

/* platform id for display purposes */
#define PLATFORM_ID_LSB "Description:	Ubuntu 22.04.5 LTS"

/* default port for omrelp */
#define RELP_DFLT_PT "514"

/* Define version of librelp used. */
/* #undef RELP_VERSION */

/* Define as the return type of signal handlers (`int' or `void'). */
#define RETSIGTYPE void

/* Define to the type of arg 1 for `select'. */
#define SELECT_TYPE_ARG1 int

/* Define to the type of args 2, 3 and 4 for `select'. */
#define SELECT_TYPE_ARG234 (fd_set *)

/* Define to the type of arg 5 for `select'. */
#define SELECT_TYPE_ARG5 (struct timeval *)

/* Define to 1 if all of the C90 standard headers exist (not just the ones
   required in a freestanding environment). This macro is provided for
   backward compatibility; new code need not use it. */
#define STDC_HEADERS 1

/* Define to 1 if strerror_r returns char *. */
#define STRERROR_R_CHAR_P 1

/* network support is integrated. */
#define SYSLOG_INET 1

/* Define to 1 if you can safely include both <sys/time.h> and <time.h>. This
   macro is obsolete. */
#define TIME_WITH_SYS_TIME 1

/* Define to 1 if your <sys/time.h> declares `struct tm'. */
/* #undef TM_IN_SYS_TIME */

/* Define if you want to use GSSAPI */
/* #undef USE_GSSAPI */

/* Using XXHASH for hash64. */
/* #undef USE_HASH_XXHASH */

/* Define if you want to enable libuuid support */
#define USE_LIBUUID 1

/* Enable extensions on AIX 3, Interix.  */
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
/* Enable extensions specified by ISO/IEC TS 18661-4:2015.  */
#ifndef __STDC_WANT_IEC_60559_FUNCS_EXT__
# define __STDC_WANT_IEC_60559_FUNCS_EXT__ 1
#endif
/* Enable extensions specified by ISO/IEC TS 18661-3:2015.  */
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


/* If defined, the select() syscall won't be limited to a particular number of
   file descriptors. */
/* #undef USE_UNLIMITED_SELECT */

/* Defined if valgrind support settings are to be enabled (e.g. prevents
   dlclose()). */
/* #undef VALGRIND */

/* Version number of package */
#define VERSION "8.2504.0"

/* month part of real rsyslog version */
#define VERSION_MONTH 4

/* year part of real rsyslog version */
#define VERSION_YEAR 25

/* Define to 1 if `lex' declares `yytext' as a `char *' by default, not a
   `char[]'. */
#define YYTEXT_POINTER 1

/* Number of bits in a file offset, on hosts where this is settable. */
/* #undef _FILE_OFFSET_BITS */

/* Define for large files, on AIX-style hosts. */
/* #undef _LARGE_FILES */

/* Use POSIX pthread semantics */
#define _POSIX_PTHREAD_SEMANTICS 1

/* Define for Solaris 2.5.1 so the uint8_t typedef from <sys/synch.h>,
   <pthread.h>, or <semaphore.h> is not used. If the typedef were allowed, the
   #define below would cause a syntax error. */
/* #undef _UINT8_T */

/* Use X/Open CAE Specification */
/* #undef _XOPEN_SOURCE */

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to `int' if <sys/types.h> doesn't define. */
/* #undef gid_t */

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
/* #undef inline */
#endif

/* Define to `int' if <sys/types.h> does not define. */
/* #undef mode_t */

/* Define to `long int' if <sys/types.h> does not define. */
/* #undef off_t */

/* Define as a signed integer type capable of holding a process identifier. */
/* #undef pid_t */

/* Define to `unsigned int' if <sys/types.h> does not define. */
/* #undef size_t */

/* Define to `int' if <sys/types.h> does not define. */
/* #undef ssize_t */

/* Define to `int' if <sys/types.h> doesn't define. */
/* #undef uid_t */

/* Define to the type of an unsigned integer type of width exactly 8 bits if
   such a type exists and the standard includes do not define it. */
/* #undef uint8_t */

/* Define as `fork' if `vfork' does not work. */
/* #undef vfork */

/* Define to empty if the keyword `volatile' does not work. Warning: valid
   code using `volatile' can become incorrect without. Disable with care. */
/* #undef volatile */
