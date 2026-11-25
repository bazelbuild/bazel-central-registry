/// @file
/// @brief Smoke test for kmod's multi-call binary and its compat commands.
///
/// A module tree lib/modules/1.0.0 is laid out under $TEST_TMPDIR with the
/// fake module, then depmod indexes it and modinfo and modprobe read it back;
/// nothing is loaded into the running kernel.  The programs are resolved
/// through the runfiles library from the rlocationpaths the cc_test forwards
/// in its `env`, and the compat commands through their symlinks, since kmod
/// decides what it is from argv[0].  Linux only, as kmod is.

#include <sys/stat.h>
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

/// @brief What one command produced.
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

/// @brief Reads a whole file, exiting 2 when it cannot be opened.
std::string read_file(const std::string& path) {
  std::ifstream in(path, std::ios::binary);
  if (!in) {
    std::cerr << "Failed to open " << path << ": " << std::strerror(errno)
              << "\n";
    std::exit(2);
  }
  std::ostringstream out;
  out << in.rdbuf();
  return out.str();
}

/// @brief Copies `from` to `to`, exiting 2 on failure.
void copy_file(const std::string& from, const std::string& to) {
  std::ofstream out(to, std::ios::binary | std::ios::trunc);
  const std::string content = read_file(from);
  out.write(content.data(), static_cast<std::streamsize>(content.size()));
  if (!out) {
    std::cerr << "Failed to write " << to << ": " << std::strerror(errno)
              << "\n";
    std::exit(2);
  }
}

/// @brief mkdir -p for the handful of directories the module tree needs.
void make_dirs(const std::string& path) {
  for (std::size_t slash = path.find('/', 1); slash != std::string::npos;
       slash = path.find('/', slash + 1)) {
    mkdir(path.substr(0, slash).c_str(), 0755);
  }
  if (mkdir(path.c_str(), 0755) != 0 && errno != EEXIST) {
    std::cerr << "Failed to create " << path << ": " << std::strerror(errno)
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

/// @brief Runs `program` with `args`, capturing stdout and stderr together.
RunResult run(const std::string& program,
              const std::vector<std::string>& args) {
  std::string cmd = shell_quote(program);
  for (const std::string& arg : args) {
    cmd.push_back(' ');
    cmd += shell_quote(arg);
  }
  cmd += " 2>&1";
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

/// @brief The programs under test and the tally of cases.
struct Fixture {
  std::string kmod;
  std::string modinfo;
  std::string depmod;
  std::string modprobe;
  std::string base_dir;
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

  /// @brief Runs `program` with `args` and requires exit 0 and every string
  /// of `expected` somewhere in its output.
  void expect_contains(const std::string& name, const std::string& program,
                       const std::vector<std::string>& args,
                       const std::vector<std::string>& expected) {
    RunResult r = run(program, args);
    if (r.exit_code != 0) {
      fail(name, "exited " + std::to_string(r.exit_code) + "; output:\n" +
                     r.output);
      return;
    }
    for (const std::string& needle : expected) {
      if (r.output.find(needle) == std::string::npos) {
        fail(name, "output lacks `" + needle + "`:\n" + r.output);
        return;
      }
    }
    pass(name);
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

  Fixture f{resolve(*runfiles, "KMOD_RLOCATIONPATH"),
            resolve(*runfiles, "MODINFO_RLOCATIONPATH"),
            resolve(*runfiles, "DEPMOD_RLOCATIONPATH"),
            resolve(*runfiles, "MODPROBE_RLOCATIONPATH"), temp_dir()};

  // The module tree depmod and modprobe work on: -b/-d name its base, -S the
  // kernel release, so neither looks at the host's /lib/modules.
  const std::string module_dir = f.base_dir + "/lib/modules/1.0.0";
  make_dirs(module_dir);
  const std::string fake_ko = module_dir + "/fake.ko";
  copy_file(resolve(*runfiles, "FAKE_KO_RLOCATIONPATH"), fake_ko);

  // PACKAGE_VERSION from config.h, and KMOD_FEATURES on the next line.
  f.expect_contains("version", f.kmod, {"--version"}, {"kmod version 34.4\n"});

  // modinfo reads the .modinfo strings of the ELF object.
  f.expect_contains("modinfo", f.modinfo, {fake_ko},
                    {"license:        GPL", "alias:          bazel:fake",
                     "parm:           level:verbosity (int)"});

  // depmod indexes the tree: modules.dep and modules.alias are written from
  // the module's depends= and alias= strings.  (It warns about the missing
  // modules.order and modules.builtin a kernel build would have left.)
  f.expect_contains("depmod", f.depmod, {"-b", f.base_dir, "1.0.0"}, {});
  {
    const std::string dep = read_file(module_dir + "/modules.dep");
    const std::string alias = read_file(module_dir + "/modules.alias");
    if (dep.find("fake.ko:") == std::string::npos) {
      f.fail("depmod_index", "modules.dep lacks fake.ko:\n" + dep);
    } else if (alias.find("alias bazel:fake fake") == std::string::npos) {
      f.fail("depmod_index", "modules.alias lacks the alias:\n" + alias);
    } else {
      f.pass("depmod_index");
    }
  }

  // modprobe resolves the alias through the indexes and, in dry-run form,
  // prints the insmod it would do.
  f.expect_contains("modprobe_resolve_alias", f.modprobe,
                    {"-d", f.base_dir, "-S", "1.0.0", "-R", "bazel:fake"},
                    {"fake\n"});
  f.expect_contains("modprobe_show_depends", f.modprobe,
                    {"-d", f.base_dir, "-S", "1.0.0", "--show-depends", "fake"},
                    {"insmod ", "/lib/modules/1.0.0/fake.ko"});

  std::cout << f.passed << "/" << f.total << " tests passed\n";
  return f.passed == f.total ? 0 : 1;
}
