/// @file
/// @brief Runs one driver of bash's own test suite against the built shell.
///
/// Upstream's `tests/run-<name>` scripts each run `${THIS_SH} ./<name>.tests`
/// and `diff` the output against `<name>.right`, exiting non-zero on a
/// difference.  This program stages the suite into $TEST_TMPDIR (the scripts
/// write files beside themselves), puts the support tools the suite expects on
/// PATH, and runs the driver with the built bash as both the shell under test
/// and the interpreter of the driver, so no host shell takes part.  The
/// binaries and files come through the runfiles library from the rlocationpaths
/// the cc_test forwards in its `env`.  POSIX only: the module itself does not
/// build on Windows.

#include <fcntl.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

#include <cerrno>
#include <clocale>
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

/// @brief Prints `what` with the current errno and exits 2 (a harness error,
/// not a test failure).
[[noreturn]] void die(const std::string& what) {
  std::cerr << what << ": " << std::strerror(errno) << "\n";
  std::exit(2);
}

/// @brief Returns the environment variable `name`, exiting 2 when unset.
std::string required_env(const char* name) {
  const char* value = std::getenv(name);
  if (value == nullptr || value[0] == '\0') {
    std::cerr << name << " is not set; not run by the cc_test of tests/BUILD.bazel?\n";
    std::exit(2);
  }
  return value;
}

/// @brief Splits a space-separated list, as `$(rlocationpaths ...)` expands.
std::vector<std::string> split_words(const std::string& text) {
  std::vector<std::string> out;
  std::istringstream in(text);
  for (std::string word; in >> word;) {
    out.push_back(word);
  }
  return out;
}

/// @brief Creates `dir` and its parents, like `mkdir -p`.
void make_dirs(const std::string& dir) {
  for (size_t slash = dir.find('/', 1); slash != std::string::npos; slash = dir.find('/', slash + 1)) {
    const std::string parent = dir.substr(0, slash);
    if (mkdir(parent.c_str(), 0755) != 0 && errno != EEXIST) {
      die("mkdir " + parent);
    }
  }
  if (mkdir(dir.c_str(), 0755) != 0 && errno != EEXIST) {
    die("mkdir " + dir);
  }
}

/// @brief Copies `source` to `dest`, creating parent directories and keeping
/// the source's permission bits (a few scripts are executed by `#!` line).
void copy_file(const std::string& source, const std::string& dest, mode_t extra_mode) {
  struct stat info;
  if (stat(source.c_str(), &info) != 0) {
    die("stat " + source);
  }
  make_dirs(dest.substr(0, dest.rfind('/')));
  std::ifstream in(source, std::ios::binary);
  std::ofstream out(dest, std::ios::binary | std::ios::trunc);
  out << in.rdbuf();
  if (!in || !out) {
    die("copy " + source + " -> " + dest);
  }
  out.close();
  if (chmod(dest.c_str(), (info.st_mode & 0777) | 0600 | extra_mode) != 0) {
    die("chmod " + dest);
  }
}

/// @brief Resolves one rlocationpath, exiting 2 when the runfiles library
/// cannot (a data file missing from the cc_test).
std::string resolve(const Runfiles& runfiles, const std::string& rlocationpath) {
  const std::string path = runfiles.Rlocation(rlocationpath);
  if (path.empty() || access(path.c_str(), R_OK) != 0) {
    std::cerr << "Cannot resolve runfile " << rlocationpath << "\n";
    std::exit(2);
  }
  return path;
}

/// @brief The suite-relative name of a staged file: the part of its
/// rlocationpath after the `tests/` package directory.
std::string suite_relative(const std::string& rlocationpath) {
  const std::string marker = "/tests/";
  const size_t at = rlocationpath.find(marker);
  if (at == std::string::npos) {
    std::cerr << rlocationpath << " is not under the tests/ package\n";
    std::exit(2);
  }
  return rlocationpath.substr(at + marker.size());
}

/// @brief Runs `program` with `args` from `cwd`, inheriting stdout and stderr
/// so a driver's diff output lands in the test log; returns its exit status.
int run(const std::string& program, const std::vector<std::string>& args, const std::string& cwd) {
  std::vector<char*> argv;
  argv.push_back(const_cast<char*>(program.c_str()));
  for (const std::string& arg : args) {
    argv.push_back(const_cast<char*>(arg.c_str()));
  }
  argv.push_back(nullptr);
  const pid_t pid = fork();
  if (pid < 0) {
    die("fork");
  }
  if (pid == 0) {
    if (chdir(cwd.c_str()) != 0) {
      die("chdir " + cwd);
    }
    execv(program.c_str(), argv.data());
    die("exec " + program);
  }
  int status = 0;
  if (waitpid(pid, &status, 0) < 0) {
    die("waitpid");
  }
  if (WIFSIGNALED(status)) {
    std::cerr << program << " died with signal " << WTERMSIG(status) << "\n";
    return 128 + WTERMSIG(status);
  }
  return WEXITSTATUS(status);
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 2) {
    std::cerr << "usage: suite_runner run-<name>\n";
    return 2;
  }
  const std::string driver = argv[1];
  // Three things no test environment can be made to have: a locale the scripts switch to
  // (en_US.UTF-8, which the registry's Linux images do not install) and an unprivileged
  // user (the images run as root, and ulimit and permission cases expect to be refused).
  // A driver the cc_test marks as needing one of them is skipped, loudly, where it is
  // missing; upstream's own README says as much for root.
  if (const char* locale = std::getenv("REQUIRED_LOCALE"); locale != nullptr && locale[0] != '\0') {
    if (setlocale(LC_ALL, locale) == nullptr) {
      std::cerr << driver << ": skipped, the " << locale << " locale is not installed on this host\n";
      return 0;
    }
    setlocale(LC_ALL, "C");
  }
  if (std::getenv("NOT_AS_ROOT") != nullptr && geteuid() == 0) {
    std::cerr << driver << ": skipped, its permission and resource-limit cases expect an unprivileged user\n";
    return 0;
  }
  // builtins11.sub raises the soft core-file limit to unlimited, which the hard limit must
  // allow; the registry's macOS runners cap it.
  if (std::getenv("NEEDS_UNLIMITED_CORE") != nullptr) {
    struct rlimit core;
    if (getrlimit(RLIMIT_CORE, &core) == 0 && core.rlim_max != RLIM_INFINITY) {
      std::cerr << driver << ": skipped, the hard core-file limit is " << core.rlim_max
                << " and its ulimit cases need unlimited\n";
      return 0;
    }
  }
  std::string error;
  std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
  if (runfiles == nullptr) {
    std::cerr << "Runfiles: " << error << "\n";
    return 2;
  }

  const std::string root = required_env("TEST_TMPDIR");
  const std::string suite_dir = root + "/tests";
  const std::string bin_dir = root + "/bin";
  const std::string tmp_dir = root + "/tmp";
  make_dirs(suite_dir);
  make_dirs(bin_dir);
  make_dirs(tmp_dir);

  for (const std::string& path : split_words(required_env("SUITE_RLOCATIONPATHS"))) {
    copy_file(resolve(*runfiles, path), suite_dir + "/" + suite_relative(path), 0);
  }
  // recho, zecho and printenv, which the scripts find on PATH, plus the shell
  // itself under the name the scripts that read ${BUILD_DIR}/bash expect.
  for (const std::string& path : split_words(required_env("TOOL_RLOCATIONPATHS"))) {
    copy_file(resolve(*runfiles, path), bin_dir + path.substr(path.rfind('/')), 0111);
  }
  const std::string shell = bin_dir + "/bash";
  copy_file(resolve(*runfiles, required_env("BASH_RLOCATIONPATH")), shell, 0111);
  // tests/heredoc5.sub reads config.h, version.h and y.tab.c from ${BUILD_DIR}.
  for (const std::string& path : split_words(required_env("BUILD_DIR_RLOCATIONPATHS"))) {
    copy_file(resolve(*runfiles, path), bin_dir + path.substr(path.rfind('/')), 0);
  }

  // The .right files were written under a UTF-8 locale (help's two-column layout, the
  // multibyte cases); the test environment has none set.  The first UTF-8 locale the C
  // library accepts becomes LANG, and the driver runs in the C locale when there is none.
  for (const char* candidate : {"C.UTF-8", "en_US.UTF-8", "C.utf8", "en_US.utf8"}) {
    if (setlocale(LC_ALL, candidate) != nullptr) {
      setenv("LANG", candidate, 1);
      break;
    }
  }
  setlocale(LC_ALL, "C");
  // What tests/run-all arranges before running a driver.
  setenv("THIS_SH", shell.c_str(), 1);
  setenv("BUILD_DIR", bin_dir.c_str(), 1);
  setenv("TMPDIR", tmp_dir.c_str(), 1);
  const std::string output = tmp_dir + "/bashtst-" + driver;
  setenv("BASH_TSTOUT", output.c_str(), 1);
  const char* old_path = std::getenv("PATH");
  const std::string path = bin_dir + ":" + (old_path == nullptr ? "/usr/bin:/bin" : old_path);
  setenv("PATH", path.c_str(), 1);
  unsetenv("BASH_ENV");
  unsetenv("SHELLOPTS");
  unsetenv("BASHOPTS");

  const int status = run(shell, {driver}, suite_dir);
  if (status != 0) {
    std::cerr << driver << " failed with exit status " << status << " (diff output above)\n";
    return 1;
  }
  return 0;
}
