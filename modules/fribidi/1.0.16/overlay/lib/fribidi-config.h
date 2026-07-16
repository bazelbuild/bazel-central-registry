#ifndef FRIBIDI_CONFIG_H
#define FRIBIDI_CONFIG_H

#define FRIBIDI "fribidi"
#define FRIBIDI_NAME "GNU FriBidi"
#define FRIBIDI_BUGREPORT "https://github.com/fribidi/fribidi/issues/new"

#define FRIBIDI_VERSION "1.0.16"
#define FRIBIDI_MAJOR_VERSION 1
#define FRIBIDI_MINOR_VERSION 0
#define FRIBIDI_MICRO_VERSION 16
#define FRIBIDI_INTERFACE_VERSION 4
#define FRIBIDI_INTERFACE_VERSION_STRING "4"

/* The size of a `int', as computed by sizeof. 4 on all supported platforms
   (LP64/LLP64); fribidi-types.h only checks >= 4. */
#define FRIBIDI_SIZEOF_INT 4

/* FRIBIDI_BUILT_WITH_MSVC left undefined: no source file references it. */

#endif /* FRIBIDI_CONFIG_H */
