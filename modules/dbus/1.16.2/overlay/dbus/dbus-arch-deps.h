#if !defined (DBUS_INSIDE_DBUS_H) && !defined (DBUS_COMPILATION)
#error "Only <dbus/dbus.h> can be included directly, this file may disappear or change contents."
#endif

#ifndef DBUS_ARCH_DEPS_H
#define DBUS_ARCH_DEPS_H

#include <dbus/dbus-macros.h>
#include <stdint.h>

DBUS_BEGIN_DECLS

#define DBUS_HAVE_INT64 1
typedef int64_t dbus_int64_t;
typedef uint64_t dbus_uint64_t;
#define DBUS_INT64_MODIFIER "ll"

#define DBUS_INT64_CONSTANT(val)  (val##LL)
#define DBUS_UINT64_CONSTANT(val) (val##ULL)

typedef int32_t dbus_int32_t;
typedef uint32_t dbus_uint32_t;

typedef int16_t dbus_int16_t;
typedef uint16_t dbus_uint16_t;

#define DBUS_SIZEOF_VOID_P 8

#define DBUS_MAJOR_VERSION 1
#define DBUS_MINOR_VERSION 16
#define DBUS_MICRO_VERSION 2

#define DBUS_VERSION_STRING "1.16.2"
#define DBUS_VERSION ((1 << 16) | (16 << 8) | (2))

DBUS_END_DECLS

#endif
