// Static Bazel overlay replacement for the cmake-generated poppler_private_export.h.
// cmake generates this via generate_export_header(poppler BASE_NAME poppler-private ...).
// For a static library build, all symbols are exported by default.

#ifndef POPPLER_PRIVATE_EXPORT_H
#define POPPLER_PRIVATE_EXPORT_H

#ifdef _WIN32
  #define POPPLER_PRIVATE_EXPORT __declspec(dllexport)
#elif defined(__GNUC__) || defined(__clang__)
  #define POPPLER_PRIVATE_EXPORT __attribute__((visibility("default")))
#else
  #define POPPLER_PRIVATE_EXPORT
#endif

#define POPPLER_PRIVATE_NO_EXPORT

#ifndef POPPLER_PRIVATE_DEPRECATED
  #define POPPLER_PRIVATE_DEPRECATED __attribute__((__deprecated__))
#endif

#ifndef POPPLER_PRIVATE_DEPRECATED_EXPORT
  #define POPPLER_PRIVATE_DEPRECATED_EXPORT POPPLER_PRIVATE_EXPORT POPPLER_PRIVATE_DEPRECATED
#endif

#ifndef POPPLER_PRIVATE_DEPRECATED_NO_EXPORT
  #define POPPLER_PRIVATE_DEPRECATED_NO_EXPORT POPPLER_PRIVATE_NO_EXPORT POPPLER_PRIVATE_DEPRECATED
#endif

#endif /* POPPLER_PRIVATE_EXPORT_H */
