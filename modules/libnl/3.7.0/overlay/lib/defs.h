/* Configuration for Linux with glibc. */
#define HAVE_STRERROR_L 1
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
#define HAVE_LITTLE_ENDIAN 1
#elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define HAVE_BIG_ENDIAN 1
#endif
