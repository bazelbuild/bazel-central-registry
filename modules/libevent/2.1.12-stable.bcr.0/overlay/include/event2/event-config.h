#ifndef EVENT2_EVENT_CONFIG_H_INCLUDED_
#define EVENT2_EVENT_CONFIG_H_INCLUDED_

#include "event2-config_common.h"

#if defined(__linux__)
#include "event2-config_linux.h"
#elif defined(__APPLE__)
#include "event2-config_apple.h"
#elif defined(_MSC_VER)
#include "event2-config_msvc.h"
#endif

#endif  // EVENT2_EVENT_CONFIG_H_INCLUDED_
