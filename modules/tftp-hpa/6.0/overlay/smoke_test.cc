// Smoke test for the tftp-hpa binaries.
//
// tftp-hpa 6.0 ships no test suite of its own, so this simply confirms a
// binary can be executed, parses its arguments, and reports the expected
// version instead of crashing on startup.
//
// Usage: smoke_test <rlocationpath-of-binary> <expected-version>

#include <cstdio>
#include <cstdlib>
#include <memory>
#include <string>

#include "rules_cc/cc/runfiles/runfiles.h"

#ifdef _WIN32
#define POPEN _popen
#define PCLOSE _pclose
#else
#define POPEN popen
#define PCLOSE pclose
#endif

using rules_cc::cc::runfiles::Runfiles;

namespace {

// Runs `command` and appends everything it writes to stdout/stderr to
// `output`. Returns the exit status reported by pclose(), or -1 on failure.
int run(const std::string& command, std::string* output) {
  FILE* pipe = POPEN(command.c_str(), "r");
  if (pipe == nullptr) {
    return -1;
  }

  char buffer[4096];
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    output->append(buffer);
  }

  return PCLOSE(pipe);
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 3) {
    fprintf(stderr, "Usage: %s <rlocationpath> <expected-version>\n", argv[0]);
    return 2;
  }

  const std::string rlocationpath = argv[1];
  const std::string expected = std::string("tftp-hpa ") + argv[2];

  std::string error;
  std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
  if (runfiles == nullptr) {
    fprintf(stderr, "Failed to initialize runfiles: %s\n", error.c_str());
    return 1;
  }

  const std::string binary = runfiles->Rlocation(rlocationpath);
  if (binary.empty()) {
    fprintf(stderr, "Failed to locate runfile: %s\n", rlocationpath.c_str());
    return 1;
  }

  // `-V` makes both tftp and tftpd print their version banner and exit 0.
  const std::string command = "\"" + binary + "\" -V 2>&1";

  std::string output;
  const int status = run(command, &output);
  fputs(output.c_str(), stderr);

  if (status != 0) {
    fprintf(stderr, "`%s` exited with status %d\n", command.c_str(), status);
    return 1;
  }

  if (output.find(expected) == std::string::npos) {
    fprintf(stderr, "`%s` did not report `%s`\n", command.c_str(),
            expected.c_str());
    return 1;
  }

  return 0;
}
