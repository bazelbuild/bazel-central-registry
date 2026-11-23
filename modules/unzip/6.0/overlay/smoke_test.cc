/// @file
/// @brief Runs one of the programs on one of the files, both named by their
/// rlocationpath, and exits with the program's status.
///
/// The Makefile's `check` target runs the freshly built programs on
/// testmake.zip from the build directory.  Under Bazel the archive and the
/// program are runfiles, which on Windows may exist only in the manifest, so
/// this wrapper resolves both through the runfiles library and spawns the
/// program with the flags in between passed through unchanged:
///
///     smoke_test <program rlocationpath> [flags...] <file rlocationpath>

#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "rules_cc/cc/runfiles/runfiles.h"

#ifdef _WIN32
#include <process.h>
#else
#include <spawn.h>
#include <sys/wait.h>

extern char** environ;
#endif

using rules_cc::cc::runfiles::Runfiles;

/// @brief Runs `argv` (`argv[0]` an absolute program path) and waits for it.
/// @return The program's exit status, or 1 when it could not be started or
/// did not exit normally.
static int run(const std::vector<std::string>& argv) {
  std::vector<char*> c_argv;
  for (const std::string& arg : argv) {
    c_argv.push_back(const_cast<char*>(arg.c_str()));
  }
  c_argv.push_back(nullptr);
#ifdef _WIN32
  return static_cast<int>(_spawnv(_P_WAIT, argv[0].c_str(), c_argv.data()));
#else
  pid_t pid;
  if (posix_spawn(&pid, argv[0].c_str(), nullptr, nullptr, c_argv.data(),
                  environ) != 0) {
    std::cerr << "smoke_test: cannot start " << argv[0] << "\n";
    return 1;
  }
  int status = 0;
  if (waitpid(pid, &status, 0) < 0 || !WIFEXITED(status)) {
    return 1;
  }
  return WEXITSTATUS(status);
#endif
}

int main(int argc, char** argv) {
  if (argc < 3) {
    std::cerr << "usage: smoke_test <program> [flags...] <file>\n";
    return 2;
  }
  std::string error;
  std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
  if (runfiles == nullptr) {
    std::cerr << "smoke_test: " << error << "\n";
    return 1;
  }
  std::vector<std::string> command;
  command.push_back(runfiles->Rlocation(argv[1]));
  for (int i = 2; i < argc - 1; ++i) {
    command.push_back(argv[i]);
  }
  command.push_back(runfiles->Rlocation(argv[argc - 1]));
  for (const std::string& word : command) {
    std::cout << word << " ";
  }
  std::cout << "\n";
  return run(command);
}
