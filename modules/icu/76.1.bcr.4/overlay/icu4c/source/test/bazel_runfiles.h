/* Bazel runfiles resolver, C-callable.
 *
 * The implementation is in C++ (bazel_runfiles.cc) and links against the original
 * @rules_cc//cc/runfiles. This header exposes an extern "C" interface so that both
 * C (cintltst) and C++ (intltest, iotest) test code can use it with a single include.
 */
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Resolves an rlocationpath to an absolute filesystem path using the Bazel
 * runfiles library.
 *
 * rlocation_path must be a canonical runfiles-root-relative path as produced
 * by $(rlocationpath ...) in a BUILD file, e.g.
 * "icu+/icu4c/source/test/testdata/testdata_dir".
 *
 * Returns a pointer to a process-lifetime buffer (caller must NOT free it),
 * or nullptr/NULL if the runfiles library cannot initialise (no env vars set).
 */
const char* icu_bazel_rlocation(const char* rlocation_path);

#ifdef __cplusplus
}
#endif
