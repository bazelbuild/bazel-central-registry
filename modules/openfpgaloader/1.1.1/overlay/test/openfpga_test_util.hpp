// SPDX-License-Identifier: Apache-2.0
//
// Shared helpers for the openFPGALoader smoke / integration tests. Header-only
// so the two `cc_test` targets that consume it don't need a separate
// `cc_library` — each test binary compiles the helper into its own TU.

#ifndef TEST_OPENFPGA_TEST_UTIL_HPP_
#define TEST_OPENFPGA_TEST_UTIL_HPP_

#include <cstdio>
#include <cstdlib>
#include <memory>
#include <string>

#include "gtest/gtest.h"
#include "rules_cc/cc/runfiles/runfiles.h"

#ifdef _WIN32
#include <io.h>
#define OFL_TEST_POPEN _popen
#define OFL_TEST_PCLOSE _pclose
// cmd.exe uses double quotes to group arguments.
#define OFL_TEST_Q "\""
#else
#include <sys/wait.h>
#include <unistd.h>
#define OFL_TEST_POPEN popen
#define OFL_TEST_PCLOSE pclose
// /bin/sh uses single quotes to disable interpolation.
#define OFL_TEST_Q "'"
#endif

namespace openfpga_test {

struct Result {
    int exit_code;
    std::string output;
};

inline Result RunWithArg(const std::string& binary, const std::string& arg) {
    std::string cmd = OFL_TEST_Q + binary + OFL_TEST_Q + " " + arg + " 2>&1";
    FILE* fp = OFL_TEST_POPEN(cmd.c_str(), "r");
    if (fp == nullptr) {
        return {-1, "popen failed"};
    }

    std::string out;
    char buf[4096];
    while (std::fgets(buf, sizeof(buf), fp) != nullptr) {
        out.append(buf);
    }

    int raw = OFL_TEST_PCLOSE(fp);
    int rc;
#ifdef _WIN32
    rc = raw;
#else
    rc = WIFEXITED(raw) ? WEXITSTATUS(raw) : -1;
#endif
    return {rc, out};
}

// Resolves the openFPGALoader binary path from the runfiles tree. The BUILD
// wires OPENFPGALOADER_RLOCATIONPATH via `$(rlocationpath ...)`, which honours
// the module repo-mapping and the Windows `.exe` suffix so we don't have to
// reason about either here. Cached in a function-local static so the runfiles
// manifest is parsed once, not per-TEST.
inline const std::string& OpenFpgaLoaderBinary() {
    using rules_cc::cc::runfiles::Runfiles;
    static const std::string kBinary = [] {
        std::string error;
        std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
        if (runfiles == nullptr) {
            ADD_FAILURE() << "runfiles init failed: " << error;
            return std::string();
        }
        const char* rlocationpath =
            std::getenv("OPENFPGALOADER_RLOCATIONPATH");
        if (rlocationpath == nullptr) {
            ADD_FAILURE() << "OPENFPGALOADER_RLOCATIONPATH not set";
            return std::string();
        }
        std::string bin = runfiles->Rlocation(rlocationpath);
        if (bin.empty()) {
            ADD_FAILURE() << "cannot resolve runfiles path: " << rlocationpath;
        }
        return bin;
    }();
    return kBinary;
}

}  // namespace openfpga_test

#endif  // TEST_OPENFPGA_TEST_UTIL_HPP_
