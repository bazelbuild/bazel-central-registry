// C-callable Bazel runfiles resolver (C++ implementation).
// See bazel_runfiles.h for the public interface.

#include "bazel_runfiles.h"
#include "rules_cc/cc/runfiles/runfiles.h"

#include <string>
#include <unordered_map>

using rules_cc::cc::runfiles::Runfiles;

const char* icu_bazel_rlocation(const char* rlocation_path) {
    // Lazily initialise one shared Runfiles instance. Create() checks RUNFILES_MANIFEST_FILE
    // and RUNFILES_DIR in the environment, which are set by both `bazel test` and `bazel run`.
    // Pass an empty argv0 (not needed when env vars are present) and BAZEL_CURRENT_REPOSITORY
    // for correct bzlmod repo-mapping.
    static Runfiles* rf = Runfiles::Create("", BAZEL_CURRENT_REPOSITORY);

    if (rf == nullptr || rlocation_path == nullptr) return nullptr;

    // Cache results: Rlocation() can be called thousands of times per test
    // run, but the resolved paths are always the same within one process.
    static std::unordered_map<std::string, std::string> cache;

    auto it = cache.find(rlocation_path);
    if (it != cache.end()) {
        return it->second.c_str();
    }

    std::string resolved = rf->Rlocation(rlocation_path);
    if (resolved.empty()) return nullptr;

    return cache.emplace(rlocation_path, std::move(resolved)).first->second.c_str();
}
