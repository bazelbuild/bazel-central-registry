#ifndef OPJ_CONFIG_PRIVATE_H_INCLUDED
#define OPJ_CONFIG_PRIVATE_H_INCLUDED

#define OPJ_PACKAGE_VERSION "2.5.4"

#if !defined(_WIN32)
#define OPJ_HAVE_FSEEKO 1
#define OPJ_HAVE_POSIX_MEMALIGN 1
#if !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200112L
#endif
#endif

#if defined(__BYTE_ORDER__) && defined(__ORDER_BIG_ENDIAN__) && \
    __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define OPJ_BIG_ENDIAN
#endif

#endif
