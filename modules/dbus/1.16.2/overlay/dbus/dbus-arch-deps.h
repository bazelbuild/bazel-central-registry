/* dbus-arch-deps.h, pre-generated from upstream's dbus/dbus-arch-deps.h.in.
 *
 * Upstream's configure picks the first 8-byte type from int, long, long long
 * (cmake/ConfigureChecks.cmake, meson.build). That is `long` on LP64 platforms
 * (64-bit Linux, macOS, BSDs) and `long long` on ILP32 platforms, so select on
 * the data model to produce the same result as upstream's configure.
 */
#if !defined (DBUS_INSIDE_DBUS_H) && !defined (DBUS_COMPILATION)
#error "Only <dbus/dbus.h> can be included directly, this file may disappear or change contents."
#endif

#ifndef DBUS_ARCH_DEPS_H
#define DBUS_ARCH_DEPS_H

#include <dbus/dbus-macros.h>

DBUS_BEGIN_DECLS

/* D-Bus no longer supports platforms with no 64-bit integer type. */
#define DBUS_HAVE_INT64 1

#if defined(__LP64__) || defined(_LP64)
_DBUS_GNUC_EXTENSION typedef long dbus_int64_t;
_DBUS_GNUC_EXTENSION typedef unsigned long dbus_uint64_t;
#define DBUS_INT64_MODIFIER "l"

#define DBUS_INT64_CONSTANT(val)  (_DBUS_GNUC_EXTENSION (val##L))
#define DBUS_UINT64_CONSTANT(val) (_DBUS_GNUC_EXTENSION (val##UL))

#define DBUS_SIZEOF_VOID_P 8
#else
_DBUS_GNUC_EXTENSION typedef long long dbus_int64_t;
_DBUS_GNUC_EXTENSION typedef unsigned long long dbus_uint64_t;
#define DBUS_INT64_MODIFIER "ll"

#define DBUS_INT64_CONSTANT(val)  (_DBUS_GNUC_EXTENSION (val##LL))
#define DBUS_UINT64_CONSTANT(val) (_DBUS_GNUC_EXTENSION (val##ULL))

#define DBUS_SIZEOF_VOID_P 4
#endif

typedef int dbus_int32_t;
typedef unsigned int dbus_uint32_t;

typedef short dbus_int16_t;
typedef unsigned short dbus_uint16_t;

/* This is not really arch-dependent, but it's not worth
 * creating an additional generated header just for this
 */
#define DBUS_MAJOR_VERSION 1
#define DBUS_MINOR_VERSION 16
#define DBUS_MICRO_VERSION 2

#define DBUS_VERSION_STRING "1.16.2"

#define DBUS_VERSION ((1 << 16) | (16 << 8) | (2))

DBUS_END_DECLS

#endif /* DBUS_ARCH_DEPS_H */
