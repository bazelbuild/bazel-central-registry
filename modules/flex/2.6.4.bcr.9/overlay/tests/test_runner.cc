/* Resolves SCANNER and INPUT via runfiles, redirects stdin, and exec's. */

#include <cstdio>
#include <cstdlib>
#include <memory>
#include <string>

#include "rules_cc/cc/runfiles/runfiles.h"

#ifdef _WIN32
#include <process.h>
#else
#include <unistd.h>
#endif

using rules_cc::cc::runfiles::Runfiles;

int main(int argc, char** argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s SCANNER INPUT\n", argv[0]);
        return 1;
    }

    std::string error;
    std::unique_ptr<Runfiles> runfiles(
        Runfiles::CreateForTest(BAZEL_CURRENT_REPOSITORY, &error));
    if (!runfiles) {
        fprintf(stderr, "Failed to create runfiles: %s\n", error.c_str());
        return 1;
    }

    std::string scanner = runfiles->Rlocation(argv[1]);
    std::string input = runfiles->Rlocation(argv[2]);

    if (scanner.empty()) {
        fprintf(stderr, "Could not locate scanner: %s\n", argv[1]);
        return 1;
    }
    if (input.empty()) {
        fprintf(stderr, "Could not locate input: %s\n", argv[2]);
        return 1;
    }

    if (!freopen(input.c_str(), "r", stdin)) {
        perror(input.c_str());
        return 1;
    }

#ifdef _WIN32
    intptr_t rc = _spawnl(_P_WAIT, scanner.c_str(), scanner.c_str(), NULL);
    if (rc == -1) {
        perror(scanner.c_str());
        return 1;
    }
    return static_cast<int>(rc);
#else
    execl(scanner.c_str(), scanner.c_str(), static_cast<char*>(NULL));
    perror(scanner.c_str());
    return 1;
#endif
}
