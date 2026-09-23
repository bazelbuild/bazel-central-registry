#ifndef COAL_CONFIG_HH
#define COAL_CONFIG_HH

#define COAL_VERSION_UNKNOWN_TAG 0
#define COAL_VERSION "3.0.4"
#define COAL_MAJOR_VERSION 3
#define COAL_MINOR_VERSION 0
#define COAL_PATCH_VERSION 4

#define COAL_VERSION_AT_LEAST(major, minor, patch) \
  (COAL_MAJOR_VERSION > major ||                   \
   (COAL_MAJOR_VERSION >= major &&                 \
    (COAL_MINOR_VERSION > minor ||                 \
     (COAL_MINOR_VERSION >= minor && COAL_PATCH_VERSION >= patch))))

#define COAL_VERSION_AT_MOST(major, minor, patch) \
  (COAL_MAJOR_VERSION < major ||                  \
   (COAL_MAJOR_VERSION <= major &&                \
    (COAL_MINOR_VERSION < minor ||                \
     (COAL_MINOR_VERSION <= minor && COAL_PATCH_VERSION <= patch))))

#define COAL_DLLIMPORT
#define COAL_DLLEXPORT
#define COAL_DLLLOCAL
#define COAL_DLLAPI
#define COAL_LOCAL

#endif  // COAL_CONFIG_HH
