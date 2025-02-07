#ifndef EVCONFIG_PRIVATE_H_INCLUDED_
#define EVCONFIG_PRIVATE_H_INCLUDED_

#if defined(__linux__)
#include "evconfig-private_linux.h"
#elif defined(__APPLE__)
#include "evconfig-private_apple.h"
#elif defined(_MSC_VER)
// No file needed for MSVC.
#endif

#endif  // EVCONFIG_PRIVATE_H_INCLUDED_
