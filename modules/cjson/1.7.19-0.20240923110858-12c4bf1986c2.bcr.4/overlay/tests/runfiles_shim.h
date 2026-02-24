#ifndef CJSON_TESTS_RUNFILES_SHIM_H
#define CJSON_TESTS_RUNFILES_SHIM_H

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * Resolves a runfile path using @rules_cc//cc/runfiles.
     * Returns a newly allocated string, or nullptr if not found. Caller must free it.
     */
    char* runfiles_resolve(const char* runfile_path, const char* fallback_path);

#ifdef __cplusplus
}
#endif

#endif /* CJSON_TESTS_RUNFILES_SHIM_H */
