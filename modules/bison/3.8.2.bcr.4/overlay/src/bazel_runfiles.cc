#include <cstring>
#include <string>

#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

struct BazelRunfiles {
    std::unique_ptr<Runfiles> ptr;
};

extern "C" {

static struct BazelRunfiles* bazel_runfiles = NULL;

/**
 * @brief Initialize the Bazel runfiles library for this process.
 *
 * Must be called once (typically from main()) before any other
 * bazel_runfiles_* function.  Uses BAZEL_CURRENT_REPOSITORY (compiled-in)
 * as the source repository for Runfiles::Create().  Subsequent calls are
 * no-ops.
 *
 * @param argv0_cstr  The value of argv[0] from main().
 */
void bazel_runfiles_init(const char* argv0_cstr) {
    if (bazel_runfiles != nullptr) {
        return;
    }

    Runfiles* runfiles;
    std::string argv0(argv0_cstr);
    std::string source_repository(BAZEL_CURRENT_REPOSITORY);
    std::string error;
    runfiles = Runfiles::Create(argv0, source_repository, &error);
    if (runfiles == nullptr) {
        return;
    }

    bazel_runfiles = new BazelRunfiles;
    bazel_runfiles->ptr.reset(runfiles);
}

/**
 * @brief Resolve bison's PKGDATADIR via runfiles.
 *
 * If the BISON_PKGDATADIR_RLOCATIONPATH env var is set, tries
 * Rlocation(value) directly, then Rlocation(value +
 * "/m4sugar/m4sugar.m4") with suffix stripping.
 *
 * When this function returns NULL, the caller (files.c) falls back to the
 * BISON_PKGDATADIR env var and then to the compiled-in PKGDATADIR default.
 *
 * @return A malloc'd path to the data directory, or NULL on failure.
 *         The caller is responsible for freeing the returned pointer.
 */
char* bazel_runfiles_bison_pkgdatadir() {
    if (bazel_runfiles == nullptr) {
        return nullptr;
    }

    const char* rlocationpath = getenv("BISON_PKGDATADIR_RLOCATIONPATH");
    if (rlocationpath == nullptr) {
        return nullptr;
    }

    std::string base(rlocationpath);

    std::string direct = bazel_runfiles->ptr->Rlocation(base);
    if (!direct.empty()) {
        return strdup(direct.c_str());
    }

    std::string with_file =
        bazel_runfiles->ptr->Rlocation(base + "/m4sugar/m4sugar.m4");
    if (!with_file.empty()) {
        char* datadir = strdup(with_file.c_str());
        datadir[with_file.size() - 19] = '\x00';
        return datadir;
    }

    return nullptr;
}

/**
 * @brief Resolve the m4 binary path via runfiles.
 *
 * If the M4_RLOCATIONPATH env var is set, its value is treated as an
 * rlocationpath to the m4 binary and resolved via Rlocation().
 *
 * When this function returns NULL, the caller (files.c) falls back to the
 * M4 env var and then to the default m4 path.
 *
 * @return A malloc'd absolute path to the m4 binary, or NULL on failure.
 *         The caller is responsible for freeing the returned pointer.
 */
char* bazel_runfiles_m4() {
    if (bazel_runfiles == nullptr) {
        return nullptr;
    }

    const char* m4_rlocationpath = getenv("M4_RLOCATIONPATH");
    if (m4_rlocationpath == nullptr) {
        return nullptr;
    }

    std::string result =
        bazel_runfiles->ptr->Rlocation(std::string(m4_rlocationpath));
    if (result.empty()) {
        return nullptr;
    }
    return strdup(result.c_str());
}
}
