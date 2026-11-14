#ifndef NGX_AUTO_CONFIG_H
#define NGX_AUTO_CONFIG_H

/* Ubuntu 26.10 nginx 1.30.4-7ubuntu1.1 debian/rules, applied to nginx 1.31.8. */
#define NGX_CONFIGURE \
    " --prefix=/usr/share/nginx" \
    " --conf-path=/etc/nginx/nginx.conf" \
    " --http-log-path=/var/log/nginx/access.log" \
    " --error-log-path=stderr" \
    " --lock-path=/var/lock/nginx.lock" \
    " --pid-path=/run/nginx.pid" \
    " --modules-path=/usr/lib/nginx/modules" \
    " --http-client-body-temp-path=/var/lib/nginx/body" \
    " --http-fastcgi-temp-path=/var/lib/nginx/fastcgi" \
    " --http-proxy-temp-path=/var/lib/nginx/proxy" \
    " --http-scgi-temp-path=/var/lib/nginx/scgi" \
    " --http-uwsgi-temp-path=/var/lib/nginx/uwsgi" \
    " --with-compat" \
    " --with-debug" \
    " --with-http_ssl_module" \
    " --with-http_stub_status_module" \
    " --with-http_realip_module" \
    " --with-http_auth_request_module" \
    " --with-http_v2_module" \
    " --with-http_v3_module" \
    " --with-http_dav_module" \
    " --with-http_slice_module" \
    " --build=Ubuntu" \
    " --with-threads" \
    " --with-http_addition_module" \
    " --with-http_flv_module" \
    " --with-http_gunzip_module" \
    " --with-http_gzip_static_module" \
    " --with-http_mp4_module" \
    " --with-http_random_index_module" \
    " --with-http_secure_link_module" \
    " --with-http_sub_module" \
    " --with-mail_ssl_module" \
    " --with-stream_ssl_module" \
    " --with-stream_ssl_preread_module" \
    " --with-stream_realip_module" \
    " --with-http_geoip_module=dynamic" \
    " --with-http_image_filter_module=dynamic" \
    " --with-http_perl_module=dynamic" \
    " --with-http_xslt_module=dynamic" \
    " --with-mail=dynamic" \
    " --with-stream=dynamic" \
    " --with-stream_geoip_module=dynamic"

#define NGX_BUILD "Ubuntu"
#if defined(__clang__)
#define NGX_COMPILER "clang " __clang_version__
#elif defined(__GNUC__)
#define NGX_COMPILER "gcc " __VERSION__
#endif

#define NGX_PREFIX "/usr/share/nginx/"
#define NGX_CONF_PREFIX "/etc/nginx/"
#define NGX_SBIN_PATH "sbin/nginx"
#define NGX_CONF_PATH "/etc/nginx/nginx.conf"
#define NGX_PID_PATH "/run/nginx.pid"
#define NGX_LOCK_PATH "/var/lock/nginx.lock"
#define NGX_ERROR_LOG_PATH ""
#define NGX_ERROR_LOG_STDERR 1
#define NGX_HTTP_LOG_PATH "/var/log/nginx/access.log"
#define NGX_HTTP_CLIENT_TEMP_PATH "/var/lib/nginx/body"
#define NGX_HTTP_FASTCGI_TEMP_PATH "/var/lib/nginx/fastcgi"
#define NGX_HTTP_PROXY_TEMP_PATH "/var/lib/nginx/proxy"
#define NGX_HTTP_SCGI_TEMP_PATH "/var/lib/nginx/scgi"
#define NGX_HTTP_UWSGI_TEMP_PATH "/var/lib/nginx/uwsgi"
#define NGX_USER "nobody"
#define NGX_GROUP "nogroup"

/* auto/os/conf and auto/types/sizeof for little-endian LP64 Linux. */
#if !defined(__LP64__) || __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__
#error nginx requires a little-endian LP64 target
#endif
#if defined(__aarch64__)
#define NGX_ALIGNMENT 16
#elif defined(__x86_64__)
#define NGX_HAVE_NONALIGNED 1
#else
#error nginx is configured for aarch64 and x86_64 Linux
#endif
#define NGX_CPU_CACHE_LINE 64
#define NGX_HAVE_LITTLE_ENDIAN 1
#define NGX_PTR_SIZE 8
#define NGX_SIG_ATOMIC_T_SIZE 4
#define NGX_TIME_T_SIZE 8
#define NGX_MAX_SIZE_T_VALUE 9223372036854775807LL
#define NGX_MAX_OFF_T_VALUE 9223372036854775807LL
#define NGX_MAX_TIME_T_VALUE 9223372036854775807LL
#define NGX_SIZE_T_LEN (sizeof("-9223372036854775808") - 1)
#define NGX_OFF_T_LEN NGX_SIZE_T_LEN
#define NGX_TIME_T_LEN NGX_SIZE_T_LEN

/* auto/cc/conf, auto/os/linux and auto/unix. */
#define NGX_HAVE_ACCEPT4 1
#define NGX_HAVE_ALIGNED_DIRECTIO 1
#define NGX_HAVE_BPF 1
#define NGX_HAVE_C99_VARIADIC_MACROS 1
#define NGX_HAVE_CAPABILITIES 1
#define NGX_HAVE_CLEAR_EVENT 1
#define NGX_HAVE_CLOCK_MONOTONIC 1
#define NGX_HAVE_CRYPT 1
#define NGX_HAVE_DEFERRED_ACCEPT 1
#define NGX_HAVE_DLOPEN 1
#define NGX_HAVE_D_TYPE 1
#define NGX_HAVE_EPOLL 1
#define NGX_HAVE_EPOLLEXCLUSIVE 1
#define NGX_HAVE_EPOLLRDHUP 1
#define NGX_HAVE_EVENTFD 1
#define NGX_HAVE_FIONBIO 1
#define NGX_HAVE_FIONREAD 1
#define NGX_HAVE_GCC_ATOMIC 1
#define NGX_HAVE_GCC_BSWAP64 1
#define NGX_HAVE_GCC_VARIADIC_MACROS 1
#define NGX_HAVE_GETADDRINFO 1
#define NGX_HAVE_GMTOFF 1
#define NGX_HAVE_GNU_CRYPT_R 1
#define NGX_HAVE_INET6 1
#define NGX_HAVE_IP_BIND_ADDRESS_NO_PORT 1
#define NGX_HAVE_IP_MTU_DISCOVER 1
#define NGX_HAVE_IP_PKTINFO 1
#define NGX_HAVE_IPV6_DONTFRAG 1
#define NGX_HAVE_IPV6_MTU_DISCOVER 1
#define NGX_HAVE_IPV6_RECVPKTINFO 1
#define NGX_HAVE_KEEPALIVE_TUNABLE 1
#define NGX_HAVE_LEVEL1_DCACHE_LINESIZE 1
#define NGX_HAVE_LOCALTIME_R 1
#define NGX_HAVE_MAP_ANON 1
#define NGX_HAVE_MAP_DEVZERO 1
#define NGX_HAVE_MEMALIGN 1
#define NGX_HAVE_MSGHDR_MSG_CONTROL 1
#define NGX_HAVE_OPENAT 1
#define NGX_HAVE_O_DIRECT 1
#define NGX_HAVE_O_PATH 1
#define NGX_HAVE_POSIX_FADVISE 1
#define NGX_HAVE_POSIX_MEMALIGN 1
#define NGX_HAVE_POSIX_SEM 1
#define NGX_HAVE_PREAD 1
#define NGX_HAVE_PR_SET_DUMPABLE 1
#define NGX_HAVE_PR_SET_KEEPCAPS 1
#define NGX_HAVE_PWRITE 1
#define NGX_HAVE_PWRITEV 1
#define NGX_HAVE_REUSEPORT 1
#define NGX_HAVE_SCHED_SETAFFINITY 1
#define NGX_HAVE_SCHED_YIELD 1
#define NGX_HAVE_SC_NPROCESSORS_ONLN 1
#define NGX_HAVE_SENDFILE 1
#define NGX_HAVE_SENDFILE64 1
#define NGX_HAVE_STATFS 1
#define NGX_HAVE_STATVFS 1
#define NGX_HAVE_SYSVSHM 1
#define NGX_HAVE_SYS_EVENTFD_H 1
#define NGX_HAVE_TCP_FASTOPEN 1
#define NGX_HAVE_TCP_INFO 1
#define NGX_HAVE_TRANSPARENT_PROXY 1
#define NGX_HAVE_UNIX_DOMAIN 1

#include <netinet/udp.h>
#ifdef UDP_SEGMENT
#define NGX_HAVE_UDP_SEGMENT 1
#endif
#ifdef __GLIBC__
#if __GLIBC_PREREQ(2, 32)
#define NGX_HAVE_STRERRORDESC_NP 1
#endif
#endif

/* auto/modules, auto/lib/conf, auto/threads and auto/stubs. */
#define NGX_COMPAT 1
#define NGX_CRYPT 1
#define NGX_DEBUG 1
#define NGX_HTTP_CACHE 1
#define NGX_HTTP_DAV 1
#define NGX_HTTP_GZIP 1
#define NGX_HTTP_HEADERS 1
#define NGX_HTTP_REALIP 1
#define NGX_HTTP_SSI 1
#define NGX_HTTP_SSL 1
#define NGX_HTTP_UPSTREAM_LEAST_TIME 1
#define NGX_HTTP_UPSTREAM_SID 1
#define NGX_HTTP_UPSTREAM_STICKY 1
#define NGX_HTTP_UPSTREAM_ZONE 1
#define NGX_HTTP_V2 1
#define NGX_HTTP_V3 1
#define NGX_HTTP_X_FORWARDED_FOR 1
#define NGX_MAIL_SSL 1
#define NGX_OPENSSL 1
#define NGX_PCRE 1
#define NGX_PCRE2 1
#define NGX_QUIC 1
#define NGX_QUIC_BPF 1
#define NGX_SMP 1
#define NGX_SSL 1
#define NGX_STAT_STUB 1
#define NGX_STREAM_SSL 1
#define NGX_STREAM_UPSTREAM_LEAST_TIME 1
#define NGX_STREAM_UPSTREAM_ZONE 1
#define NGX_SUPPRESS_WARN 1
#define NGX_THREADS 1
#define NGX_ZLIB 1

#endif
