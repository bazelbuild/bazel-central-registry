// Smoke test for the GNU grep binary produced by the Bazel port.
//
// Each subtest writes an input file into $TEST_TMPDIR, invokes grep on it,
// captures stdout, and asserts on exit status and content. Grep is driven
// through the runfiles library so the test also validates that the binary
// can be launched at the same path a downstream consumer would use.
//
// Only the matchers that are always compiled in are exercised: -G/-E/-F and
// the option plumbing around them. -P is deliberately untested because
// `--@grep//:perl_regexp=false` is a supported configuration.

#ifdef _WIN32
// _popen / _pclose live in <stdio.h> on MSVC/clang-cl and are also
// exposed by MinGW's stdio.h; alias to the portable names below so the
// rest of the file stays branch-free.
#define POPEN _popen
#define PCLOSE _pclose
#else
#define POPEN popen
#define PCLOSE pclose
#endif

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <memory>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "rules_cc/cc/runfiles/runfiles.h"
#include "tests/test_support.h"

using grep_tests::exit_status;
using grep_tests::for_command_interpreter;
using grep_tests::shell_quote;
using grep_tests::temp_dir;
using grep_tests::write_file;
using rules_cc::cc::runfiles::Runfiles;

namespace {

struct RunResult {
  int exit_code = -1;
  std::string stdout_capture;
};

// Invoke grep with the given arguments and capture stdout. stderr is left
// going to the test log so failures stay diagnosable.
RunResult run_grep(const std::string& grep_path,
                   const std::vector<std::string>& args) {
  std::string cmd = shell_quote(grep_path);
  for (const auto& arg : args) {
    cmd.push_back(' ');
    cmd += shell_quote(arg);
  }
  cmd = for_command_interpreter(std::move(cmd));

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
  if (status == -1) {
    std::cerr << "pclose failed: " << std::strerror(errno) << "\n";
    std::exit(2);
  }
  result.exit_code = exit_status(status);
  return result;
}

// Strip every `\r` (grep opens files in text mode on Windows, and the shell
// terminates lines with `\r\n`) and one trailing `\n`, so comparisons stay
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

// The haystack every subtest greps over unless it supplies its own.
constexpr std::string_view kCorpus =
    "alpha one\n"
    "Beta two\n"
    "gamma three\n"
    "delta a.c\n"
    "epsilon abc\n"
    "alphabet soup\n";

struct Fixture {
  std::string grep_path;
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

  // Write `input` to a scratch file, run grep with `args` followed by that
  // file, and require the given exit status and stdout (trailing newline
  // stripped, CRLF normalized).
  void run_expecting(const std::string& name,
                     std::string_view input,
                     const std::vector<std::string>& args,
                     std::string_view expected_stdout,
                     int expected_exit = 0) {
    const std::string input_path = tmp_dir + "/" + name + ".txt";
    write_file(input_path, input);

    std::vector<std::string> argv = args;
    argv.push_back(input_path);

    RunResult r = run_grep(grep_path, argv);
    if (r.exit_code != expected_exit) {
      fail(name, "grep exited " + std::to_string(r.exit_code) + ", wanted " +
                     std::to_string(expected_exit) +
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

  // `GREP_RLOCATIONPATH` is set by the cc_test's `env` attribute to
  // `$(rlocationpath //:grep)`. That's the runfiles-relative path (with
  // the correct `.exe` suffix on Windows and the right repository prefix
  // for bzlmod vs WORKSPACE), so we avoid hard-coding either here.
  const char* rlocationpath = std::getenv("GREP_RLOCATIONPATH");
  if (rlocationpath == nullptr || rlocationpath[0] == '\0') {
    std::cerr << "GREP_RLOCATIONPATH is not set; the test target must forward "
                 "`$(rlocationpath //:grep)` through the `env` attribute.\n";
    return 2;
  }
  std::string grep_path = runfiles->Rlocation(rlocationpath);
  if (grep_path.empty()) {
    std::cerr << "Could not resolve runfile " << rlocationpath << "\n";
    return 2;
  }

  Fixture f{std::move(grep_path), temp_dir()};

  // Sanity: --version exits 0 and prints the GNU grep banner.
  {
    RunResult r = run_grep(f.grep_path, {"--version"});
    if (r.exit_code != 0) {
      f.fail("version", "grep --version exited " + std::to_string(r.exit_code));
    } else if (r.stdout_capture.find("GNU grep") == std::string::npos) {
      f.fail("version", "banner missing 'GNU grep'; got: " + r.stdout_capture);
    } else {
      f.pass("version");
    }
  }

  // Default matcher (BRE): plain substring.
  f.run_expecting("bre_literal", kCorpus, {"alpha"},
                  "alpha one\n"
                  "alphabet soup");

  // BRE metacharacters: `.` and `*` go through dfasearch.
  f.run_expecting("bre_meta", kCorpus, {"^g.*three$"}, "gamma three");

  // ERE alternation and grouping exercise the same DFA with -E syntax.
  f.run_expecting("ere_alternation", kCorpus, {"-E", "(Beta|delta) "},
                  "Beta two\n"
                  "delta a.c");

  // ERE back-reference falls back to the regex backtracker.
  f.run_expecting("ere_backref", "abcabc\nabcdef\n", {"-E", "(abc)\\1"},
                  "abcabc");

  // -F treats the pattern literally: `a.c` must not match `abc`.
  f.run_expecting("fixed_string", kCorpus, {"-F", "a.c"}, "delta a.c");

  // -i folds case (kwsearch/dfasearch case-folding path).
  f.run_expecting("ignore_case", kCorpus, {"-i", "BETA"}, "Beta two");

  // -v inverts, -c counts: both are pure grep.c option plumbing.
  f.run_expecting("invert_count", kCorpus, {"-vc", "alpha"}, "4");

  // -n prefixes line numbers.
  f.run_expecting("line_numbers", kCorpus, {"-n", "epsilon"}, "5:epsilon abc");

  // -w requires word boundaries, so `alpha` must not match `alphabet`.
  f.run_expecting("word_regexp", kCorpus, {"-w", "alpha"}, "alpha one");

  // -o prints each match rather than each line.
  f.run_expecting("only_matching", kCorpus, {"-oE", "al[a-z]+"},
                  "alpha\n"
                  "alphabet");

  // -x anchors the whole line.
  f.run_expecting("line_regexp", kCorpus, {"-x", "Beta two"}, "Beta two");

  // Multiple patterns via repeated -e.
  f.run_expecting("multiple_patterns", kCorpus, {"-e", "^alpha ", "-e", "^gamma"},
                  "alpha one\n"
                  "gamma three");

  // No match is exit 1 with empty stdout; grep.c must not report it as error.
  f.run_expecting("no_match", kCorpus, {"nonexistent-needle"}, "", 1);

  // A missing operand is exit 2, distinct from "no match".
  {
    RunResult r =
        run_grep(f.grep_path, {"pattern", f.tmp_dir + "/does-not-exist.txt"});
    if (r.exit_code != 2) {
      f.fail("missing_file", "grep exited " + std::to_string(r.exit_code) +
                                 ", wanted 2");
    } else {
      f.pass("missing_file");
    }
  }

  std::cout << f.passed << "/" << f.total << " tests passed\n";
  return f.passed == f.total ? 0 : 1;
}
