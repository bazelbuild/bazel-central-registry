/* SPDX-License-Identifier: MPL-2.0 */

#ifndef __ZMQ_PLATFORM_HPP_INCLUDED__
#define __ZMQ_PLATFORM_HPP_INCLUDED__

#define ZMQ_USE_CV_IMPL_STL11

#if defined(_WIN32)

#define ZMQ_HAVE_WINDOWS
#define ZMQ_IOTHREAD_POLLER_USE_SELECT
#define ZMQ_POLL_BASED_ON_SELECT
#define HAVE_STRNLEN 1
#define HAVE_IF_NAMETOINDEX 1
#define ZMQ_CACHELINE_SIZE 64

#elif defined(__APPLE__)

#define ZMQ_HAVE_OSX
#define ZMQ_IOTHREAD_POLLER_USE_KQUEUE
#define ZMQ_POLL_BASED_ON_POLL
#define HAVE_POSIX_MEMALIGN 1
#define ZMQ_CACHELINE_SIZE 64
#define HAVE_FORK 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_MKDTEMP 1
#define ZMQ_HAVE_UIO 1
#define ZMQ_HAVE_NOEXCEPT 1
#define ZMQ_HAVE_IFADDRS 1
#define ZMQ_HAVE_LOCAL_PEERCRED 1
#define ZMQ_HAVE_SO_KEEPALIVE 1
#define ZMQ_HAVE_TCP_KEEPALIVE 1
#define ZMQ_HAVE_TCP_KEEPINTVL 1
#define ZMQ_HAVE_TCP_KEEPCNT 1
#define ZMQ_HAVE_PTHREAD_SETNAME_1 1
#define HAVE_STRNLEN 1
#define ZMQ_HAVE_STRLCPY 1
#define ZMQ_HAVE_IPC 1
#define ZMQ_HAVE_STRUCT_SOCKADDR_UN 1
#define HAVE_IF_NAMETOINDEX 1

#elif defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || defined(__DragonFly__) || defined(__OpenBSD__) || defined(__NetBSD__)

#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__)
#define ZMQ_HAVE_FREEBSD
#endif
#if defined(__DragonFly__)
#define ZMQ_HAVE_DRAGONFLY
#endif
#if defined(__OpenBSD__)
#define ZMQ_HAVE_OPENBSD
#endif
#if defined(__NetBSD__)
#define ZMQ_HAVE_NETBSD
#endif

#define ZMQ_IOTHREAD_POLLER_USE_KQUEUE
#define ZMQ_POLL_BASED_ON_POLL
#define HAVE_POSIX_MEMALIGN 1
#define ZMQ_CACHELINE_SIZE 64
#define HAVE_FORK 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_MKDTEMP 1
#define ZMQ_HAVE_UIO 1
#define ZMQ_HAVE_NOEXCEPT 1
#define ZMQ_HAVE_IFADDRS 1
#define ZMQ_HAVE_SO_KEEPALIVE 1
#define ZMQ_HAVE_TCP_KEEPALIVE 1
#define HAVE_STRNLEN 1
#define ZMQ_HAVE_STRLCPY 1
#define ZMQ_HAVE_IPC 1
#define ZMQ_HAVE_STRUCT_SOCKADDR_UN 1
#define HAVE_IF_NAMETOINDEX 1

#elif defined(__linux__) || defined(__ANDROID__)

#if defined(__ANDROID__)
#define ZMQ_HAVE_ANDROID
#define ZMQ_HAVE_STRLCPY 1
#else
#define ZMQ_HAVE_LINUX
#include <features.h>
#if defined(__GLIBC__) && defined(__GLIBC_PREREQ)
#if __GLIBC_PREREQ(2, 38)
#define ZMQ_HAVE_STRLCPY 1
#endif
#elif !defined(__GLIBC__)
// Non-glibc Linux (e.g. musl) provides strlcpy
#define ZMQ_HAVE_STRLCPY 1
#endif
#endif

#define ZMQ_IOTHREAD_POLLER_USE_EPOLL
#define ZMQ_IOTHREAD_POLLER_USE_EPOLL_CLOEXEC
#define ZMQ_POLL_BASED_ON_POLL
#define ZMQ_HAVE_PPOLL 1
#define HAVE_POSIX_MEMALIGN 1
#define ZMQ_CACHELINE_SIZE 64
#define HAVE_FORK 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_MKDTEMP 1
#define ZMQ_HAVE_UIO 1
#define ZMQ_HAVE_NOEXCEPT 1
#define ZMQ_HAVE_EVENTFD 1
#define ZMQ_HAVE_EVENTFD_CLOEXEC 1
#define ZMQ_HAVE_IFADDRS 1
#define ZMQ_HAVE_SO_BINDTODEVICE 1
#define ZMQ_HAVE_SO_PEERCRED 1
#define ZMQ_HAVE_BUSY_POLL 1
#define ZMQ_HAVE_O_CLOEXEC 1
#define ZMQ_HAVE_SOCK_CLOEXEC 1
#define ZMQ_HAVE_SO_KEEPALIVE 1
#define ZMQ_HAVE_SO_PRIORITY 1
#define ZMQ_HAVE_TCP_KEEPCNT 1
#define ZMQ_HAVE_TCP_KEEPIDLE 1
#define ZMQ_HAVE_TCP_KEEPINTVL 1
#define ZMQ_HAVE_TCP_KEEPALIVE 1
#define ZMQ_HAVE_PTHREAD_SETNAME_2 1
#define ZMQ_HAVE_PTHREAD_SET_AFFINITY 1
#define HAVE_ACCEPT4 1
#define HAVE_STRNLEN 1
#define ZMQ_HAVE_IPC 1
#define ZMQ_HAVE_STRUCT_SOCKADDR_UN 1
#define HAVE_IF_NAMETOINDEX 1

#else

#define ZMQ_IOTHREAD_POLLER_USE_SELECT
#define ZMQ_POLL_BASED_ON_POLL
#define ZMQ_CACHELINE_SIZE 64
#define HAVE_STRNLEN 1

#endif

#endif
