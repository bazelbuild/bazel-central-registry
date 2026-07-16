/// @file runfiles_util.cc
/// @brief C wrapper around the rules_cc C++ runfiles library.

#include "bazel/runfiles_util.h"

#include <cstdlib>
#include <cstring>
#include <string>

#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

static Runfiles *g_runfiles = nullptr;

static void init_runfiles() {
    if (g_runfiles != nullptr) return;
    std::string error;
    g_runfiles = Runfiles::CreateForTest(&error);
    if (g_runfiles == nullptr) {
        g_runfiles = Runfiles::Create("", &error);
    }
}

extern "C" char *mpfr_rlocation(const char *rlocation_path) {
    init_runfiles();
    if (g_runfiles == nullptr) return nullptr;

    std::string resolved = g_runfiles->Rlocation(rlocation_path);
    if (resolved.empty()) return nullptr;

    char *result = static_cast<char *>(malloc(resolved.size() + 1));
    if (result != nullptr) {
        memcpy(result, resolved.c_str(), resolved.size() + 1);
    }
    return result;
}
