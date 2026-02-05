#pragma once

#include <rules_autoconf/config.h>

#define OPUS_BUILD 1

#define PACKAGE_BUGREPORT "opus@xiph.org"
#define PACKAGE_NAME "opus"
#define PACKAGE_STRING "opus 1.6"
#define PACKAGE_TARNAME "opus"
#define PACKAGE_URL ""
#define PACKAGE_VERSION "1.6"

#define VAR_ARRAYS 1
#define ENABLE_HARDENING 1
#define DISABLE_DEBUG_FLOAT 1

#ifndef restrict
#define restrict __restrict
#endif
