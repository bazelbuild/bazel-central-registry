#ifndef GPSD_CONFIG_H
#define GPSD_CONFIG_H

#define VERSION "3.27.5"
#define REVISION "release-3.27.5"
#define GPSD_PROTO_VERSION_MAJOR 16
#define GPSD_PROTO_VERSION_MINOR 1
#define GPSD_URL "https://gpsd.io/"
#define MAX_CLIENTS 64
#define MAX_DEVICES 6

#if !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L
#endif

#if !defined(_DEFAULT_SOURCE)
#define _DEFAULT_SOURCE
#endif

#if !defined(_DARWIN_C_SOURCE)
#define _DARWIN_C_SOURCE 1
#endif

#define AIVDM_ENABLE 1
#define SOCKET_EXPORT_ENABLE 1

#define HAVE_ARPA_INET_H 1
#define HAVE_CFMAKERAW 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_DAEMON 1
#define HAVE_FCNTL 1
#define HAVE_NETDB_H 1
#define HAVE_NETINET_IN_H 1
#define HAVE_STDATOMIC_H 1
#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__)
#define HAVE_STRLCAT 1
#define HAVE_STRLCPY 1
#endif
#define HAVE_STRNLEN 1
#define HAVE_STPNCPY 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_UN_H 1
#define HAVE_SYSLOG_H 1

#endif
