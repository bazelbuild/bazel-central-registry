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
 * by $(rlocationpath ...) in a BUILD file. Sub-paths may be appended with
 * adjacent string literals at the call site (preprocessor concatenation):
 *
 *     icu_bazel_rlocation(BAZEL_ICU_TESTDATA_SRC_DIR "/out");
 *
 * Returns a pointer to a process-lifetime buffer (caller must NOT free it),
 * or nullptr/NULL if the runfiles library cannot initialise (no env vars set).
 */
const char* icu_bazel_rlocation(const char* rlocation_path);

/**
 * Like icu_bazel_rlocation(), but appends a trailing path separator ('/') to
 * the resolved result. Intended for callers that hand the returned pointer
 * to ICU code which concatenates a relative filename directly onto it (e.g.
 * pathToDataDirectory(), loadSourceTestData()).
 */
const char* icu_bazel_rlocation_dir(const char* rlocation_path);

#ifdef __cplusplus
}
#endif
