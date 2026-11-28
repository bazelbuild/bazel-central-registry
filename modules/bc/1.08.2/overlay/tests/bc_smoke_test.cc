/// @file
/// @brief Smoke test for the bc and dc interpreters of the Bazel port.
///
/// Each case writes a program into $TEST_TMPDIR, runs the interpreter on it
/// through /bin/sh, and compares the exit status and stdout.  The binaries are
/// resolved through the runfiles library from the rlocationpaths the cc_test
/// forwards in its `env`, so the test also launches them at the path a
/// consumer would.  POSIX only: the module itself does not build on Windows.

#include <sys/wait.h>

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
#include <vector>

#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

namespace {

/// @brief What one interpreter run produced.
struct RunResult {
  int exit_code = -1;
  std::string output;
};

/// @brief Returns $TEST_TMPDIR, or exits 2 when not run by `bazel test`.
std::string temp_dir() {
  const char* env = std::getenv("TEST_TMPDIR");
  if (env == nullptr || env[0] == '\0') {
    std::cerr << "TEST_TMPDIR is not set; not running under `bazel test`?\n";
    std::exit(2);
  }
  return env;
}

/// @brief Writes `content` to `path`, exiting 2 when that fails.
void write_file(const std::string& path, std::string_view content) {
  std::ofstream out(path, std::ios::binary | std::ios::trunc);
  out.write(content.data(), static_cast<std::streamsize>(content.size()));
  if (!out) {
    std::cerr << "Failed to write " << path << ": " << std::strerror(errno)
              << "\n";
    std::exit(2);
  }
}

/// @brief Quotes one command-line token for /bin/sh.
std::string shell_quote(std::string_view arg) {
  std::string out = "'";
  for (char c : arg) {
    if (c == '\'') {
      out += "'\\''";
    } else {
      out.push_back(c);
    }
  }
  out.push_back('\'');
  return out;
}

/// @brief Runs `program` with `args` and captures its stdout; stderr goes to
/// the test log.
RunResult run(const std::string& program,
              const std::vector<std::string>& args) {
  std::string cmd = shell_quote(program);
  for (const std::string& arg : args) {
    cmd.push_back(' ');
    cmd += shell_quote(arg);
  }
  std::unique_ptr<FILE, int (*)(FILE*)> pipe(popen(cmd.c_str(), "r"), pclose);
  if (!pipe) {
    std::cerr << "popen failed for `" << cmd << "`: " << std::strerror(errno)
              << "\n";
    std::exit(2);
  }
  RunResult result;
  char buf[4096];
  while (std::size_t n = std::fread(buf, 1, sizeof(buf), pipe.get())) {
    result.output.append(buf, n);
  }
  int status = pclose(pipe.release());
  if (status == -1) {
    std::cerr << "pclose failed: " << std::strerror(errno) << "\n";
    std::exit(2);
  }
  result.exit_code = WIFEXITED(status) ? WEXITSTATUS(status)
                                       : 128 + WTERMSIG(status);
  return result;
}

/// @brief Drops one trailing newline so expectations read as the output does.
std::string trim_newline(std::string s) {
  if (!s.empty() && s.back() == '\n') s.pop_back();
  return s;
}

/// @brief The programs under test and the tally of cases.
struct Fixture {
  std::string bc_path;
  std::string dc_path;
  std::string checklib_path;
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

  /// @brief Runs `program` on `script` (written to the scratch directory,
  /// after `args`) and requires exit 0 with exactly `expected` on stdout.
  void expect_output(const std::string& name, const std::string& program,
                     std::vector<std::string> args, std::string_view script,
                     std::string_view expected) {
    const std::string script_path = tmp_dir + "/" + name + ".txt";
    write_file(script_path, script);
    args.push_back(script_path);
    RunResult r = run(program, args);
    if (r.exit_code != 0) {
      fail(name, "exited " + std::to_string(r.exit_code) +
                     "; stdout=" + r.output);
      return;
    }
    std::string actual = trim_newline(r.output);
    if (actual != expected) {
      fail(name, "output mismatch\n  expected: " + std::string(expected) +
                     "\n  actual:   " + actual);
      return;
    }
    pass(name);
  }

  /// @brief Requires `--version` to exit 0 and open with `banner`.
  void expect_version(const std::string& name, const std::string& program,
                      std::string_view banner) {
    RunResult r = run(program, {"--version"});
    if (r.exit_code != 0) {
      fail(name, "--version exited " + std::to_string(r.exit_code));
    } else if (r.output.rfind(banner, 0) != 0) {
      fail(name, "banner does not start with '" + std::string(banner) +
                     "'; got: " + r.output);
    } else {
      pass(name);
    }
  }
};

/// @brief Resolves the runfile named by the environment variable `var`.
std::string resolve(const Runfiles& runfiles, const char* var) {
  const char* rlocationpath = std::getenv(var);
  if (rlocationpath == nullptr || rlocationpath[0] == '\0') {
    std::cerr << var << " is not set; the cc_test must forward it through "
                        "`env`.\n";
    std::exit(2);
  }
  std::string path = runfiles.Rlocation(rlocationpath);
  if (path.empty()) {
    std::cerr << "Could not resolve runfile " << rlocationpath << "\n";
    std::exit(2);
  }
  return path;
}

}  // namespace

int main(int /*argc*/, char** /*argv*/) {
  std::string error;
  // The rlocationpaths carry the canonical repository name, so no source
  // repository is needed for the lookup (and Bazel 7.4 does not define
  // BAZEL_CURRENT_REPOSITORY).
  std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
  if (!runfiles) {
    std::cerr << "Failed to initialize runfiles: " << error << "\n";
    return 2;
  }

  Fixture f{resolve(*runfiles, "BC_RLOCATIONPATH"),
            resolve(*runfiles, "DC_RLOCATIONPATH"),
            resolve(*runfiles, "CHECKLIB_RLOCATIONPATH"), temp_dir()};

  // The version banners carry PACKAGE_VERSION and DC_VERSION from config.h.
  f.expect_version("bc_version", f.bc_path, "bc 1.08.2\n");
  f.expect_version("dc_version", f.dc_path, "dc 1.5.2 (GNU bc 1.08.2)\n");

  // Arbitrary-precision arithmetic through the bison parser and the number
  // library in lib/.
  f.expect_output("bc_power", f.bc_path, {}, "2^100\nquit\n",
                  "1267650600228229401496703205376");
  f.expect_output("bc_scale", f.bc_path, {}, "scale=3\n10/3\nquit\n", "3.333");
  f.expect_output("bc_function", f.bc_path, {},
                  "define f(x) { if (x <= 1) return 1; return x*f(x-1) }\n"
                  "f(20)\nquit\n",
                  "2432902008176640000");

  // -l loads the math library compiled into bc from libmath.b.
  f.expect_output("bc_math_library", f.bc_path, {"-l"}, "4*a(1)\nquit\n",
                  "3.14159265358979323844");

  // dc shares lib/ with bc and has its own evaluator.
  f.expect_output("dc_add", f.dc_path, {}, "2 3 + p\n", "5");
  f.expect_output("dc_output_radix", f.dc_path, {}, "16 o 255 p\n", "FF");
  f.expect_output("dc_precision", f.dc_path, {}, "2 k 10 3 / p\n", "3.33");

  // Upstream's Test/checklib.b evaluates every -l function over a range at a
  // scale and four digits further, and reports where the truncated results
  // disagree.  Restricted to scale 10 (the prelude sets the loop limit; the
  // script's loops always start at 10) it runs well under a second.  Two
  // results differ in their last digit there, in e(97) and s(.80); GNU bc
  // 1.07.1 reports the same two, so that count is what this port is held to.
  {
    const std::string prelude = f.tmp_dir + "/checklib_prelude.b";
    write_file(prelude, "b=10\nl=11\ni=10\n");
    RunResult r = run(f.bc_path, {"-l", prelude, f.checklib_path});
    int sections = 0;
    int failures = 0;
    std::istringstream lines(r.output);
    for (std::string line; std::getline(lines, line);) {
      constexpr std::string_view PREFIX = "Total failures: ";
      if (line.rfind(PREFIX, 0) == 0) {
        ++sections;
        failures += std::atoi(line.c_str() + PREFIX.size());
      }
    }
    if (r.exit_code != 0) {
      f.fail("checklib", "bc exited " + std::to_string(r.exit_code));
    } else if (sections != 6) {
      f.fail("checklib", "expected 6 sections (e, l, s, c, a, j), saw " +
                             std::to_string(sections) + "; output:\n" +
                             r.output);
    } else if (failures != 2) {
      f.fail("checklib", "expected the 2 last-digit differences upstream bc "
                         "reports at scale 10, saw " +
                             std::to_string(failures) + "; output:\n" +
                             r.output);
    } else {
      f.pass("checklib");
    }
  }

  std::cout << f.passed << "/" << f.total << " tests passed\n";
  return f.passed == f.total ? 0 : 1;
}
