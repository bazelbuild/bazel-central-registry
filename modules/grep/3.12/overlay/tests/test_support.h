// Helpers shared by grep_smoke_test.cc and run_grep_test.cc: the parts of
// "run a program through the platform's command interpreter" that both
// need, and the couple of Bazel-test conventions they both lean on.
//
// Naming convention: Rust-flavored snake_case for functions and variables,
// PascalCase for types. Keeps identifiers stylistically distinct from the
// Win32 API (`WriteFile`, `CreateProcess`, ...) which would otherwise be a
// live macro-collision hazard when <windows.h> is on the include path.

#ifndef GREP_TESTS_TEST_SUPPORT_H_
#define GREP_TESTS_TEST_SUPPORT_H_

#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <string>
#include <string_view>

#ifndef _WIN32
#include <sys/wait.h>
#endif

namespace grep_tests {

// $TEST_TMPDIR, or exit 2 with a hint that this is not `bazel test`.
inline std::string temp_dir() {
  const char* env = std::getenv("TEST_TMPDIR");
  if (env == nullptr || env[0] == '\0') {
    std::cerr << "TEST_TMPDIR is not set; not running under `bazel test`?\n";
    std::exit(2);
  }
  return env;
}

inline void write_file(const std::string& path, std::string_view content) {
  std::ofstream out(path, std::ios::binary | std::ios::trunc);
  if (!out) {
    std::cerr << "Failed to open " << path << ": " << std::strerror(errno) << "\n";
    std::exit(2);
  }
  out.write(content.data(), static_cast<std::streamsize>(content.size()));
  if (!out) {
    std::cerr << "Failed to write " << path << ": " << std::strerror(errno) << "\n";
    std::exit(2);
  }
}

// Quote a single command-line token for the platform shell.
//
// POSIX (/bin/sh): single-quote everything, escape embedded `'` by
// closing/reopening the quoted region — disables every metacharacter.
//
// Windows (cmd.exe via _popen/system): wrap in double quotes; embedded `"`
// are doubled per cmd.exe's parsing rules. Cmd's quoting is famously
// underspecified, but this is enough for the patterns + paths we pass.
inline std::string shell_quote(std::string_view arg) {
#ifdef _WIN32
  constexpr char kQuote = '"';
  constexpr std::string_view kEscaped = "\"\"";
#else
  constexpr char kQuote = '\'';
  constexpr std::string_view kEscaped = "'\\''";
#endif
  std::string out;
  out.reserve(arg.size() + 2);
  out.push_back(kQuote);
  for (char c : arg) {
    if (c == kQuote) {
      out.append(kEscaped);
    } else {
      out.push_back(c);
    }
  }
  out.push_back(kQuote);
  return out;
}

// Make a command line of shell_quote()d tokens safe for the interpreter that
// _popen()/system() hand it to.
//
// cmd.exe's /c parser strips the outermost quote pair when the command both
// begins and ends with `"` (which shell_quote guarantees for any argument,
// including the executable path). Without an extra outer wrap, the strip
// leaves e.g. `C:/path/grep.exe" "--version` and cmd fails with "not
// recognized as an internal or external command". See `cmd.exe /?` § "If /C
// or /K is specified ... the quote characters on the command line are
// preserved if [both conditions hold]". /bin/sh needs nothing.
inline std::string for_command_interpreter(std::string cmd) {
#ifdef _WIN32
  return "\"" + cmd + "\"";
#else
  return cmd;
#endif
}

// The child's exit status from what _pclose()/system() returned. On Windows
// that already is the exit code; on POSIX it is a wait status. A child
// killed by a signal reports as 128 + signal, the shell convention.
inline int exit_status(int status) {
#ifdef _WIN32
  return status;
#else
  if (WIFEXITED(status)) return WEXITSTATUS(status);
  return 128 + (WIFSIGNALED(status) ? WTERMSIG(status) : 0);
#endif
}

}  // namespace grep_tests

#endif  // GREP_TESTS_TEST_SUPPORT_H_
