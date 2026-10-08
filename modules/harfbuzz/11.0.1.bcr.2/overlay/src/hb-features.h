#if defined(__ANDROID__)
  #define HB_HAS_FREETYPE 1
#else
  #define HB_HAS_CAIRO 1
  #define HB_HAS_FREETYPE 1
  #define HB_HAS_GOBJECT 1
#endif
