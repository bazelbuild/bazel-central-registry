// C-callable Bazel runfiles resolver (C++ implementation).
// See bazel_runfiles.h for the public interface.

#include "bazel_runfiles.h"
#include "rules_cc/cc/runfiles/runfiles.h"
#include "unicode/putil.h"  // U_FILE_SEP_CHAR

#include <string>
#include <unordered_map>

using rules_cc::cc::runfiles::Runfiles;

namespace {

// Bazel's Runfiles::Rlocation always returns forward-slash separators. On
// Windows ICU's test code does things like
//     strrchr(path, U_FILE_SEP_CHAR)  // U_FILE_SEP_CHAR == '\\' on Windows
// against the result, which returns NULL when the path uses '/' instead of
// '\\' and the next dereference segfaults. Convert separators to the
// platform-native form (U_FILE_SEP_CHAR) before returning, so every
// downstream consumer sees a path that matches what upstream's macros
// expect. No-op on Linux / macOS where '/' is already native.
void normalize_separators(std::string& path) {
    if (U_FILE_SEP_CHAR == '/') return;
    for (char& c : path) {
        if (c == '/') c = U_FILE_SEP_CHAR;
    }
}

}  // namespace

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
    normalize_separators(resolved);

    return cache.emplace(rlocation_path, std::move(resolved)).first->second.c_str();
}

const char* icu_bazel_rlocation_dir(const char* rlocation_path) {
    const char* resolved = icu_bazel_rlocation(rlocation_path);
    if (resolved == nullptr) return nullptr;

    // Separate cache for the trailing-separator form. Keyed on the already-
    // resolved path so two rlocation inputs that resolve to the same
    // directory share one entry. Uses U_FILE_SEP_CHAR (not '/') so the
    // appended separator matches what `icu_bazel_rlocation` produced.
    static std::unordered_map<std::string, std::string> dir_cache;
    auto it = dir_cache.find(resolved);
    if (it != dir_cache.end()) {
        return it->second.c_str();
    }
    return dir_cache.emplace(resolved, std::string(resolved) + U_FILE_SEP_CHAR).first->second.c_str();
}
