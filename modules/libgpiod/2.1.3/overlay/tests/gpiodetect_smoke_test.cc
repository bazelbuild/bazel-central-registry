// Cross-version smoke test: verifies the `gpiodetect` binary produced by
// this port ran successfully under a genrule and printed output that looks
// roughly right. Assertions are version-agnostic on purpose — the same file
// serves both libgpiod 1.6.5 and 2.1.3 without edits.

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <memory>
#include <sstream>
#include <string>

#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

namespace {

// Reads the runfiles-resolved file whose rlocation path is stored in the
// given env var, and returns true iff the contents contain `substr`. Prints
// a failure diagnostic to stderr otherwise.
bool CheckOutputContains(const char* env_name, const std::string& substr) {
    const char* rlocation_path = std::getenv(env_name);
    if (rlocation_path == nullptr) {
        std::fprintf(stderr, "FAIL: env var %s is not set\n", env_name);
        return false;
    }

    std::string error;
    std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
    if (runfiles == nullptr) {
        std::fprintf(stderr, "FAIL: runfiles init failed: %s\n", error.c_str());
        return false;
    }

    const std::string path = runfiles->Rlocation(rlocation_path);
    if (path.empty()) {
        std::fprintf(stderr,
                     "FAIL: rlocation lookup failed for %s (path=%s)\n",
                     env_name, rlocation_path);
        return false;
    }

    std::ifstream f(path);
    if (!f.is_open()) {
        std::fprintf(stderr, "FAIL: could not open %s (%s)\n", env_name,
                     path.c_str());
        return false;
    }

    std::stringstream ss;
    ss << f.rdbuf();
    const std::string content = ss.str();
    if (content.find(substr) == std::string::npos) {
        std::fprintf(stderr,
                     "FAIL: %s output missing '%s'; full content:\n---\n%s---\n",
                     env_name, substr.c_str(), content.c_str());
        return false;
    }
    return true;
}

}  // namespace

int main() {
    int failures = 0;

    // `gpiodetect --version` prints `gpiodetect (libgpiod) v<X.Y.Z>` on both
    // libgpiod 1.x and 2.x — the substring below is stable across versions.
    if (!CheckOutputContains("GPIODETECT_VERSION_TXT", "(libgpiod) v")) {
        ++failures;
    }
    // `--help` prints a usage banner starting with `Usage:` on both versions.
    if (!CheckOutputContains("GPIODETECT_HELP_TXT", "Usage:")) {
        ++failures;
    }
    return failures == 0 ? 0 : 1;
}
