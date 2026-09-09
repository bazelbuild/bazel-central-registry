/// @file runfiles_util.h
/// @brief C interface for resolving Bazel runfiles paths.

#ifndef MPFR_BAZEL_RUNFILES_UTIL_H_
#define MPFR_BAZEL_RUNFILES_UTIL_H_

#ifdef __cplusplus
extern "C" {
#endif

/// @brief Resolve a Bazel rlocationpath to an absolute filesystem path.
///
/// Uses the rules_cc runfiles library to resolve @p rlocation_path
/// (e.g., "mpfr+/tests/inp_str.dat") to an absolute path that can
/// be passed to fopen().
///
/// @param rlocation_path The rlocationpath from $(rlocationpath ...).
/// @return A heap-allocated absolute path string, or NULL on failure.
///         The caller must free() the returned string.
char *mpfr_rlocation(const char *rlocation_path);

#ifdef __cplusplus
}
#endif

#endif
