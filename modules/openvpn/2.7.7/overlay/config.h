#pragma once

/* OpenVPN feature configuration for Linux. */
#define DEFAULT_DNS_UPDOWN "/usr/local/libexec/openvpn/dns-updown"
/* p11-kit exports the proxy interface from this shared library. */
#define DEFAULT_PKCS11_MODULE "libp11-kit.so.0"
#if defined(__aarch64__)
#define TARGET_ALIAS "aarch64-unknown-linux-gnu"
#elif defined(__x86_64__)
#define TARGET_ALIAS "x86_64-pc-linux-gnu"
#else
#error Unsupported OpenVPN target architecture
#endif
#define ENABLE_CRYPTO_OPENSSL 1
#define ENABLE_DCO 1
#define ENABLE_DEBUG 1
#define ENABLE_DNS_UPDOWN_BY_DEFAULT 1
#define ENABLE_FRAGMENT 1
#define ENABLE_LZ4 1
#define ENABLE_LZO 1
#define ENABLE_MANAGEMENT 1
#define ENABLE_NTLM 1
#define ENABLE_OFB_CFB_MODE 1
#define ENABLE_PKCS11 1
#define ENABLE_PLUGIN 1
#define ENABLE_PORT_SHARE 1
#define ENABLE_SITNL 1
#define ENABLE_SYSTEMD 1
#define HAVE_ARPA_INET_H 1
#define HAVE_BASENAME 1
#define HAVE_CHDIR 1
#define HAVE_CHROOT 1
#define HAVE_CMSGHDR 1
#define HAVE_DAEMON 1
#define HAVE_DIRNAME 1
#define HAVE_DLFCN_H 1
#define HAVE_DUP 1
#define HAVE_DUP2 1
#define HAVE_EPOLL_CREATE 1
#define HAVE_ERR_H 1
#define HAVE_EXECVE 1
#define HAVE_FCNTL_H 1
#define HAVE_FLOCK 1
#define HAVE_FORK 1
#define HAVE_FTRUNCATE 1
#define HAVE_GETGRNAM 1
#define HAVE_GETPWNAM 1
#define HAVE_GETRLIMIT 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_GRP_H 1
#define HAVE_IN_PKTINFO 1
#define HAVE_IPI_SPEC_DST 1
#define HAVE_LIBCAPNG 1
#define HAVE_LIBGEN_H 1
#define HAVE_LZO_LZO1X_H 1
#define HAVE_MLOCKALL 1
#define HAVE_MSGHDR 1
#define HAVE_NETDB_H 1
#define HAVE_NETINET_IN_H 1
#define HAVE_NETINET_IP_H 1
#define HAVE_NETINET_TCP_H 1
#define HAVE_NET_IF_H 1
#define HAVE_NICE 1
#define HAVE_OPENLOG 1
#define HAVE_POLL_H 1
#define HAVE_PWD_H 1
#define HAVE_RECVMSG 1
#define HAVE_RESOLV_H 1
#define HAVE_SA_FAMILY_T 1
#define HAVE_SENDMSG 1
#define HAVE_SETGID 1
#define HAVE_SETGROUPS 1
#define HAVE_SETSID 1
#define HAVE_SETUID 1
#define HAVE_STDIO_H 1
#define HAVE_STRINGS_H 1
#define HAVE_STRSEP 1
#define HAVE_SYSLOG 1
#define HAVE_SYSLOG_H 1
#define HAVE_SYS_EPOLL_H 1
#define HAVE_SYS_FILE_H 1
#define HAVE_SYS_IOCTL_H 1
#define HAVE_SYS_MMAN_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_UIO_H 1
#define HAVE_SYS_UN_H 1
#define HAVE_SYS_WAIT_H 1
#define HAVE_TERMIOS_H 1
#define HAVE_UNISTD_H 1
#define IFCONFIG_PATH ""
#define IPROUTE_PATH "/usr/sbin/ip"
#define PACKAGE "openvpn"
#define PACKAGE_NAME "OpenVPN"
#define PACKAGE_STRING "OpenVPN 2.7.7"
#define PACKAGE_VERSION "2.7.7"
#define PLUGIN_LIBDIR "/usr/local/lib/openvpn/plugins"
#define ROUTE_PATH ""
#define SYSTEMD_ASK_PASSWORD_PATH "/bin/systemd-ask-password"
#define TARGET_LINUX 1
#define VERSION "2.7.7"
