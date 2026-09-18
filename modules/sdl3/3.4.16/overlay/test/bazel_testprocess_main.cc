// Not upstream. testprocess takes childprocess's path and starts it with
// SDL_CreateProcess; ctest passes an absolute path. A Bazel test has only
// runfiles, which on Windows are a manifest, not a directory tree, so this
// launcher resolves both executables through the runfiles library.

#include <cerrno>
#include <cstdio>
#include <memory>
#include <string>
#include <vector>

#ifdef _WIN32
#include <process.h>
#else
#include <unistd.h>
#endif

#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

namespace {

std::string resolve(const Runfiles &runfiles, const char *rlocation) {
  std::string path = runfiles.Rlocation(rlocation);
#ifdef _WIN32
  // CreateProcess wants the native separator.
  for (char &c : path) {
    if (c == '/') c = '\\';
  }
#endif
  return path;
}

#ifdef _WIN32
// Quotes one argument the way the child's C runtime splits a command line
// again: a backslash is literal unless it runs into the closing quote, and an
// embedded quote needs its own backslash. Plain concatenation mangles a
// --test_arg ending in a path separator.
std::string quote(const std::string &arg) {
  std::string out = "\"";
  for (size_t i = 0; i < arg.size(); ++i) {
    size_t backslashes = 0;
    while (i < arg.size() && arg[i] == '\\') {
      ++backslashes;
      ++i;
    }
    if (i == arg.size()) {
      out.append(backslashes * 2, '\\');
      break;
    }
    if (arg[i] == '"') {
      out.append(backslashes * 2 + 1, '\\');
    } else {
      out.append(backslashes, '\\');
    }
    out.push_back(arg[i]);
  }
  out.push_back('"');
  return out;
}
#endif

}  // namespace

int main(int argc, char *argv[]) {
  if (argc < 3) {
    std::fprintf(stderr, "usage: %s <testprocess rlocation> <childprocess rlocation> [harness args...]\n", argv[0]);
    return 2;
  }

  std::string error;
  const std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
  if (runfiles == nullptr) {
    std::fprintf(stderr, "bazel_testprocess_main: cannot initialise runfiles: %s\n", error.c_str());
    return 1;
  }

  const std::string testprocess = resolve(*runfiles, argv[1]);
  const std::string childprocess = resolve(*runfiles, argv[2]);
  if (testprocess.empty() || childprocess.empty()) {
    std::fprintf(stderr, "bazel_testprocess_main: not in the runfiles: %s or %s\n", argv[1], argv[2]);
    return 1;
  }

#ifdef _WIN32
  // _spawnv joins argv into one command line, so quote each argument.
  std::vector<std::string> quoted = {quote(testprocess), quote(childprocess)};
  for (int i = 3; i < argc; ++i) quoted.push_back(quote(argv[i]));
  std::vector<const char *> child_argv;
  for (const std::string &arg : quoted) child_argv.push_back(arg.c_str());
  child_argv.push_back(nullptr);
  errno = 0;
  const intptr_t status = _spawnv(_P_WAIT, testprocess.c_str(), child_argv.data());
  // -1 is also a legitimate exit code, so errno is what separates the two.
  if (status == -1 && errno != 0) {
    std::perror("bazel_testprocess_main: _spawnv");
    return 1;
  }
  std::fprintf(stderr, "bazel_testprocess_main: testprocess exited with %d (0x%08lx)\n", static_cast<int>(status), static_cast<unsigned long>(status));
  return static_cast<int>(status);
#else
  std::vector<const char *> child_argv = {testprocess.c_str(), childprocess.c_str()};
  for (int i = 3; i < argc; ++i) child_argv.push_back(argv[i]);
  child_argv.push_back(nullptr);
  execv(testprocess.c_str(), const_cast<char *const *>(child_argv.data()));
  std::perror("bazel_testprocess_main: execv");
  return 1;
#endif
}
