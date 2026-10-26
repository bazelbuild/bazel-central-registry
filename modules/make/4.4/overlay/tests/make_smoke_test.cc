// Smoke test for the GNU Make binary produced by the Bazel port.
//
// Each subtest writes a Makefile into $TEST_TMPDIR, invokes make on it,
// captures stdout, and asserts on exit status and content. Make is driven
// through the runfiles library so the test also validates that the binary
// can be launched at the same path a downstream consumer would use.
//
// Naming convention: Rust-flavored snake_case for functions, methods, and
// variables; PascalCase for types. Keeps identifiers stylistically distinct
// from the Win32 API (`WriteFile`, `CreateProcess`, ...) which would
// otherwise be a live macro-collision hazard when <windows.h> is on the
// include path.

#ifdef _WIN32
// _popen / _pclose live in <stdio.h> on MSVC/clang-cl and are also
// exposed by MinGW's stdio.h; alias to the portable names below so the
// rest of the file stays branch-free.
#define POPEN _popen
#define PCLOSE _pclose
#else
#include <sys/wait.h>
#define POPEN popen
#define PCLOSE pclose
#endif

#include <algorithm>
#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

namespace {

std::string temp_dir() {
  const char* env = std::getenv("TEST_TMPDIR");
  if (env == nullptr || env[0] == '\0') {
    std::cerr << "TEST_TMPDIR is not set; not running under `bazel test`?\n";
    std::exit(2);
  }
  return env;
}

void write_file(const std::string& path, std::string_view content) {
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
// Windows (cmd.exe via _popen): wrap in double quotes; embedded `"` are
// doubled per cmd.exe's parsing rules. Cmd's quoting is famously
// underspecified, but this is enough for the paths + flags we pass.
std::string shell_quote(std::string_view arg) {
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

struct RunResult {
  int exit_code = -1;
  std::string stdout_capture;
};

// Invoke make with the given arguments and capture stdout. stderr is left
// going to the test log so failures stay diagnosable.
RunResult run_make(const std::string& make_path,
                   const std::vector<std::string>& args) {
  std::string cmd = shell_quote(make_path);
  for (const auto& arg : args) {
    cmd.push_back(' ');
    cmd += shell_quote(arg);
  }

#ifdef _WIN32
  // _popen invokes `cmd.exe /c <cmd>`, and cmd's /c parser strips the
  // outermost quote pair when the command both begins and ends with `"`
  // (which shell_quote guarantees for any argument, including the
  // executable path). Without an extra outer wrap, the strip leaves
  // e.g. `C:/path/make.exe" "--version` and cmd fails with "not
  // recognized as an internal or external command". See `cmd.exe /?` §
  // "If /C or /K is specified ... the quote characters on the command
  // line are preserved if [both conditions hold]".
  cmd = "\"" + cmd + "\"";
#endif

  std::unique_ptr<FILE, int (*)(FILE*)> pipe(POPEN(cmd.c_str(), "r"), PCLOSE);
  if (!pipe) {
    std::cerr << "popen failed for `" << cmd << "`: "
              << std::strerror(errno) << "\n";
    std::exit(2);
  }

  RunResult result;
  char buf[4096];
  while (std::size_t n = std::fread(buf, 1, sizeof(buf), pipe.get())) {
    result.stdout_capture.append(buf, n);
  }

  int status = PCLOSE(pipe.release());
#ifdef _WIN32
  // _pclose returns the child's exit code directly on Windows.
  result.exit_code = status;
#else
  if (status == -1) {
    std::cerr << "pclose failed: " << std::strerror(errno) << "\n";
    std::exit(2);
  }
  if (WIFEXITED(status)) {
    result.exit_code = WEXITSTATUS(status);
  } else {
    result.exit_code = 128 + (WIFSIGNALED(status) ? WTERMSIG(status) : 0);
  }
#endif
  return result;
}

// Strip every `\r` (cmd.exe's built-in `echo` writes CRLF; Windows shells
// terminate lines with `\r\n`) and one trailing `\n`, so comparisons stay
// platform-agnostic. LF-only with no trailing newline is the canonical form.
std::string canonicalize_output(std::string_view s) {
  std::string out;
  out.reserve(s.size());
  for (char c : s) {
    if (c != '\r') out.push_back(c);
  }
  if (!out.empty() && out.back() == '\n') out.pop_back();
  return out;
}

struct Fixture {
  std::string make_path;
  std::string tmp_dir;
  int total = 0;
  int passed = 0;

  void pass(std::string_view name) {
    ++total;
    ++passed;
    std::cout << "[PASS] " << name << "\n";
  }

  void fail(std::string_view name, std::string_view detail) {
    ++total;
    std::cerr << "[FAIL] " << name << ": " << detail << "\n";
  }

  // Convenience: write a Makefile, run make on it, and require exit 0 +
  // stdout matching `expected` (trailing newline stripped, CRLF normalized).
  void run_expecting(const std::string& name,
                     std::string_view makefile_content,
                     const std::vector<std::string>& extra_args,
                     std::string_view expected_stdout) {
    const std::string makefile_path = tmp_dir + "/" + name + ".mk";
    write_file(makefile_path, makefile_content);

    std::vector<std::string> args = {"-f", makefile_path};
    args.insert(args.end(), extra_args.begin(), extra_args.end());

    RunResult r = run_make(make_path, args);
    if (r.exit_code != 0) {
      fail(name, "make exited " + std::to_string(r.exit_code) +
                     "; stdout=" + r.stdout_capture);
      return;
    }
    std::string actual = canonicalize_output(r.stdout_capture);
    if (actual != expected_stdout) {
      fail(name, "output mismatch\n  expected: " + std::string(expected_stdout) +
                     "\n  actual:   " + actual);
      return;
    }
    pass(name);
  }
};

}  // namespace

int main(int /*argc*/, char** /*argv*/) {
  std::string error;
  std::unique_ptr<Runfiles> runfiles(
      Runfiles::CreateForTest(BAZEL_CURRENT_REPOSITORY, &error));
  if (!runfiles) {
    std::cerr << "Failed to initialize runfiles: " << error << "\n";
    return 2;
  }

  // `MAKE_RLOCATIONPATH` is set by the cc_test's `env` attribute to
  // `$(rlocationpath //:make)`. That's the runfiles-relative path (with
  // the correct `.exe` suffix on Windows and the right repository prefix
  // for bzlmod vs WORKSPACE), so we avoid hard-coding either here.
  const char* rlocationpath = std::getenv("MAKE_RLOCATIONPATH");
  if (rlocationpath == nullptr || rlocationpath[0] == '\0') {
    std::cerr << "MAKE_RLOCATIONPATH is not set; the test target must forward "
                 "`$(rlocationpath //:make)` through the `env` attribute.\n";
    return 2;
  }
  std::string make_path = runfiles->Rlocation(rlocationpath);
  if (make_path.empty()) {
    std::cerr << "Could not resolve runfile " << rlocationpath << "\n";
    return 2;
  }

  Fixture f{std::move(make_path), temp_dir(), 0, 0};

  // Sanity: --version exits 0 and prints the GNU Make banner.
  {
    RunResult r = run_make(f.make_path, {"--version"});
    if (r.exit_code != 0) {
      f.fail("version", "make --version exited " + std::to_string(r.exit_code));
    } else if (r.stdout_capture.find("GNU Make") == std::string::npos) {
      f.fail("version", "banner missing 'GNU Make'; got: " + r.stdout_capture);
    } else {
      f.pass("version");
    }
  }

  // Recipe execution + default goal.
  f.run_expecting(
      "hello",
      ".PHONY: all hello\n"
      "all: hello\n"
      "hello:\n"
      "\t@echo hello from make\n",
      /*extra_args=*/{},
      "hello from make");

  // Substitution reference: $(OBJS:.o=.c).
  f.run_expecting(
      "substref",
      "OBJS := main.o util.o\n"
      "SRCS := $(OBJS:.o=.c)\n"
      ".PHONY: all\n"
      "all:\n"
      "\t@echo $(SRCS)\n",
      /*extra_args=*/{},
      "main.c util.c");

  // Built-in functions exercise function.c end-to-end.
  f.run_expecting(
      "functions",
      "FILES := c.h b.h a.h\n"
      "SRCS := $(sort $(patsubst %.h,%.c,$(FILES)))\n"
      ".PHONY: all\n"
      "all:\n"
      "\t@echo $(SRCS)\n",
      /*extra_args=*/{},
      "a.c b.c c.c");

  // Recipe failure must propagate a non-zero exit. `exit 1` is portable
  // across /bin/sh and cmd.exe; `false` isn't a cmd built-in.
  {
    const std::string mk = f.tmp_dir + "/fail.mk";
    write_file(mk,
               ".PHONY: fail\n"
               "fail:\n"
               "\t@exit 1\n");
    RunResult r = run_make(f.make_path, {"-f", mk, "fail"});
    if (r.exit_code == 0) {
      f.fail("fail_propagation", "make exited 0 despite failing recipe");
    } else {
      f.pass("fail_propagation");
    }
  }

  // Parallel jobs go through the jobserver (MAKE_JOBSERVER=1 in config.h).
  // Order isn't stable, so sort before comparing.
  {
    const std::string mk = f.tmp_dir + "/parallel.mk";
    write_file(mk,
               ".PHONY: all a b\n"
               "all: a b\n"
               "a:\n"
               "\t@echo line-a\n"
               "b:\n"
               "\t@echo line-b\n");
    RunResult r = run_make(f.make_path, {"-j2", "-f", mk});
    if (r.exit_code != 0) {
      f.fail("parallel", "make exited " + std::to_string(r.exit_code));
    } else {
      std::vector<std::string> lines;
      std::stringstream ss(canonicalize_output(r.stdout_capture));
      std::string line;
      while (std::getline(ss, line)) lines.push_back(line);
      std::sort(lines.begin(), lines.end());
      if (lines.size() != 2 || lines[0] != "line-a" || lines[1] != "line-b") {
        f.fail("parallel", "unexpected output: " + r.stdout_capture);
      } else {
        f.pass("parallel");
      }
    }
  }

  std::cout << f.passed << "/" << f.total << " tests passed\n";
  return f.passed == f.total ? 0 : 1;
}
