// Runs COMMAND and passes only if it exits non-zero with EXPECTED in its stderr.
//
//   expect_failure EXPECTED COMMAND [--argument=TEXT [--runfile=RLOCATION | --temporary=NAME]]...
//
// COMMAND is the rlocation path of the program. Each --argument starts one of its arguments, TEXT, which may be empty.
// A --runfile after it appends the path of a runfile, and a --temporary appends $TEST_TMPDIR/NAME, for files the
// command writes. Runfiles are found through the runfiles library, so the test needs no runfiles tree, as on Windows.

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "process.h"
#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

namespace {

const std::string kArgumentFlag = "--argument=";
const std::string kRunfileFlag = "--runfile=";
const std::string kTemporaryFlag = "--temporary=";

bool starts_with(const std::string& text, const std::string& prefix) { return text.compare(0, prefix.size(), prefix) == 0; }

int usage(const std::string& problem) {
    std::cerr << "expect_failure: " << problem << "\n"
              << "usage: expect_failure EXPECTED COMMAND [--argument=TEXT [--runfile=RLOCATION | --temporary=NAME]]...\n";
    return 2;
}

}  // namespace

int main(int argc, char* argv[]) {
    if (argc < 3) return usage("expected EXPECTED and COMMAND");
    const std::string expected = argv[1];

    std::string runfiles_error;
    std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&runfiles_error));
    if (!runfiles) {
        std::cerr << "expect_failure: " << runfiles_error << "\n";
        return 2;
    }
    const char* test_tmpdir = std::getenv("TEST_TMPDIR");
    if (!test_tmpdir) {
        std::cerr << "expect_failure: TEST_TMPDIR is not set\n";
        return 2;
    }
    const std::string command = runfiles->Rlocation(argv[2]);

    std::vector<std::string> arguments;
    for (int index = 3; index < argc; ++index) {
        const std::string flag = argv[index];
        if (starts_with(flag, kArgumentFlag)) {
            arguments.push_back(flag.substr(kArgumentFlag.size()));
        } else if (arguments.empty()) {
            return usage("expected --argument before " + flag);
        } else if (starts_with(flag, kRunfileFlag)) {
            arguments.back() += runfiles->Rlocation(flag.substr(kRunfileFlag.size()));
        } else if (starts_with(flag, kTemporaryFlag)) {
            arguments.back() += std::string(test_tmpdir) + "/" + flag.substr(kTemporaryFlag.size());
        } else {
            return usage("unknown flag " + flag);
        }
    }

    // Named for this driver, apart from the files the command writes in the same directory.
    const std::string stderr_path = std::string(test_tmpdir) + "/expect_failure.stderr";
    int exit_code;
    std::string error;
    if (!process::run(command, arguments, nullptr, stderr_path, &exit_code, &error)) {
        std::cerr << "expect_failure: " << error << "\n";
        return 2;
    }
    std::ifstream stderr_file(stderr_path, std::ios::binary);
    std::ostringstream captured;
    captured << stderr_file.rdbuf();
    std::cerr << captured.str();

    if (exit_code != 0 && captured.str().find(expected) != std::string::npos) return 0;
    std::cerr << "expect_failure: wanted " << command << " to fail mentioning \"" << expected << "\"\n";
    return 1;
}
