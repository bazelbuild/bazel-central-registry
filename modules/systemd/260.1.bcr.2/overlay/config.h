// libudev needs the config.h that meson normally generates. This is a
// hand-curated minimum of the upstream output, kept down to these
// categories:
//
//  - feature-test macros (consumed by glibc/kernel headers, not by the
//    systemd source itself; kept defensively)
//  - ABI assumptions: GPERF_LEN_TYPE + SIZEOF_*
//  - module identity (PROJECT_VERSION + VERSION_TAG)
//  - HAVE_* / ENABLE_* probe results that gate #if blocks
//  - cosmetic strings/numerics referenced by code that libudev's
//    exported symbols don't transitively reach. Set to "" / 0 to make
//    their irrelevance obvious. (TTY_MODE is the exception: it has
//    assert_cc bit-pattern checks in src/basic/terminal-util.h.)
//
// Roughly 225 macros from the upstream config.h are omitted entirely
// because nothing in the compile set even references them. To
// regenerate after a systemd bump: `meson setup`, dump config.h, and
// cross-reference against the .c/.h files matched by the BUILD globs.

#pragma once

/* Visible to glibc/kernel headers; absent from systemd source. */
#define _GNU_SOURCE 1
#define _LARGEFILE64_SOURCE 1
#define __SANE_USERSPACE_TYPES__

/* Target ABI / typedef expansion — must be accurate. */
#define GPERF_LEN_TYPE size_t
#define SIZEOF_DEV_T 8
#define SIZEOF_INO_T 8
#define SIZEOF_RLIM_T 8
#define SIZEOF_TIME_T 8
#define SIZEOF_TIMEX_MEMBER 8

// Module identity. Matches the source tarball and overlay directory name.
#define PROJECT_VERSION 260
#define PROJECT_VERSION_FULL "260.1"
#define VERSION_TAG "260.1"

// HAVE_* / ENABLE_* probe results.
#define BPF_FRAMEWORK 0
#define BUILD_MODE_DEVELOPER 0
#define ENABLE_COMPAT_MUTABLE_UID_BOUNDARIES 0
#define ENABLE_DEBUG_HASHMAP 0
#define ENABLE_DEBUG_MMAP_CACHE 0
#define ENABLE_DEBUG_SIPHASH 0
#define ENABLE_EFI 0
#define ENABLE_GSHADOW 0
#define ENABLE_IDN 0
#define ENABLE_IMA 0
#define ENABLE_IPE 0
#define ENABLE_LOGIND 0
#define ENABLE_SMACK 0
#define ENABLE_UTMP 0
#define HAVE_ACL 0
#define HAVE_ADD_KEY 0
#define HAVE_APPARMOR 0
#define HAVE_ARCHIVE_ENTRY_GID_IS_SET 0
#define HAVE_ARCHIVE_ENTRY_HARDLINK_IS_SET 0
#define HAVE_ARCHIVE_ENTRY_UID_IS_SET 0
#define HAVE_AUDIT 0
#define HAVE_BLKID 0
#define HAVE_BPF 0
#define HAVE_BZIP2 0
#define HAVE_COMPRESSION 0
#define HAVE_CRYPT_TOKEN_SET_EXTERNAL_PATH 0
#define HAVE_ELFUTILS 0
#define HAVE_EPOLL_PWAIT2 1
#define HAVE_FCHMODAT2 0
#define HAVE_FSCONFIG 1
#define HAVE_FSMOUNT 1
#define HAVE_FSOPEN 1
#define HAVE_GCRYPT 0
#define HAVE_GET_MEMPOLICY 0
#define HAVE_GNUTLS 0
#define HAVE_IOPRIO_GET 0
#define HAVE_IOPRIO_SET 0
#define HAVE_KCMP 0
#define HAVE_KEYCTL 0
#define HAVE_KMOD 0
#define HAVE_LIBARCHIVE 0
#define HAVE_LIBBPF 0
#define HAVE_LIBCRYPT 0
#define HAVE_LIBCRYPTSETUP 0
#define HAVE_LIBCRYPTSETUP_PLUGINS 0
#define HAVE_LIBCURL 0
#define HAVE_LIBFDISK 0
#define HAVE_LIBFIDO2 0
#define HAVE_LIBIDN2 0
#define HAVE_LIBMOUNT 0
#define HAVE_LZ4 0
#define HAVE_MOUNT_SETATTR 1
#define HAVE_MOVE_MOUNT 1
#define HAVE_OPEN_TREE 1
#define HAVE_OPEN_TREE_ATTR 0
#define HAVE_OPENSSL 0
#define HAVE_P11KIT 0
#define HAVE_PAM 0
#define HAVE_PASSWDQC 0
#define HAVE_PCRE2 0
#define HAVE_PIDFD_OPEN 0
#define HAVE_PIDFD_SEND_SIGNAL 0
#define HAVE_PIDFD_SPAWN 0
#define HAVE_PIVOT_ROOT 0
#define HAVE_PWQUALITY 0
#define HAVE_QRENCODE 0
#define HAVE_QUOTACTL_FD 0
#define HAVE_REMOVEXATTRAT 0
#define HAVE_REQUEST_KEY 0
#define HAVE_RT_TGSIGQUEUEINFO 0
#define HAVE_SCHED_SETATTR 1
#define HAVE_SECCOMP 0
#define HAVE_SELINUX 0
#define HAVE_SET_MEMPOLICY 0
#define HAVE_SETXATTRAT 0
#define HAVE_SPLIT_BIN 1
#define HAVE_TPM2 0
#define HAVE_VALGRIND_VALGRIND_H 0
#define HAVE_VMLINUX_H 0
#define HAVE_WARNING_ZERO_AS_NULL_POINTER_CONSTANT 1
#define HAVE_WARNING_ZERO_LENGTH_BOUNDS 0
#define HAVE_XKBCOMMON 0
#define HAVE_XZ 0
#define HAVE_ZLIB 0
#define HAVE_ZSTD 0
#define LOG_MESSAGE_VERIFICATION 1
#define LOG_TRACE 0
#define SD_BOOT 0

/* TTY_MODE has assert_cc bit-pattern checks; can't be 0. */
#define TTY_MODE 0600

/* Cosmetic — only reached by compiled code that libudev's exports
 * don't transitively call. UID-base assert_cc constraints check
 * low-bits-clear, which 0 satisfies. */
#define CATALOG_DATABASE ""
#define COMPRESSION_PRIORITY_LZ4 ""
#define COMPRESSION_PRIORITY_XZ ""
#define COMPRESSION_PRIORITY_ZSTD ""
#define CONTAINER_UID_BASE_MAX 0
#define CONTAINER_UID_BASE_MIN 0
#define DEFAULT_COMPRESSION 0
#define DEFAULT_TIMEOUT_SEC 0
#define DEFAULT_USER_SHELL ""
#define DEFAULT_USER_TIMEOUT_SEC 0
#define DYNAMIC_UID_MAX 0
#define DYNAMIC_UID_MIN 0
#define EXTRA_NET_NAMING_SCHEMES
#define FALLBACK_HOSTNAME ""
#define FOREIGN_UID_BASE 0
#define GETTEXT_PACKAGE ""
#define GREETER_UID_MAX 0
#define GREETER_UID_MIN 0
#define KMOD ""
#define LIBDIR ""
#define LIBEXECDIR ""
#define NOBODY_GROUP_NAME ""
#define NOBODY_USER_NAME ""
#define NOLOGIN ""
#define PREFIX_NOSLASH ""
#define PROJECT_URL ""
#define RELATIVE_SOURCE_PATH ""
#define SYSTEM_ALLOC_GID_MIN 0
#define SYSTEM_ALLOC_UID_MIN 0
#define SYSTEM_CONFIG_UNIT_DIR ""
#define SYSTEM_DATA_UNIT_DIR ""
#define SYSTEM_ENV_GENERATOR_DIR ""
#define SYSTEM_GENERATOR_DIR ""
#define SYSTEM_GID_MAX 0
#define SYSTEM_UID_MAX 0
#define UDEVLIBEXECDIR ""
#define USER_CONFIG_UNIT_DIR ""
#define USER_DATA_UNIT_DIR ""
#define USER_ENV_GENERATOR_DIR ""
#define USER_GENERATOR_DIR ""
#define VARLINK_BRIDGES_DIR ""
