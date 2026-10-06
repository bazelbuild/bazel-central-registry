// Runs one script from GNU grep's upstream `tests/` suite.
//
// The suite is written against `make check`: each script does
// `. "${srcdir=.}/init.sh"; path_prepend_ ../src`, so it expects the working
// directory to be `<builddir>/tests` with the binaries one level up in
// `<builddir>/src`, plus the variables tests/Makefile.am's TESTS_ENVIRONMENT
// exports. Bazel hands us a flat, read-only runfiles tree instead, so this
// reassembles that layout under $TEST_TMPDIR, sets up the environment, and
// runs the script through a POSIX shell.
//
// The scripts are shell, so a shell is still needed to run them. What a
// native harness buys is that staging, environment and process control are
// one piece of code on every platform: no symlinks, no execute bit that has
// to survive the overlay download, and no bash to run the harness itself.
//
// Usage: run_grep_test GREP INIT_SH GET_MB_CUR_MAX CONFIG_H TEST_NAME
// The first four are runfiles-relative paths ($(rlocationpath ...)).

#include <cctype>
#include <cerrno>
#include <clocale>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <initializer_list>
#include <iostream>
#include <memory>
#include <string>
#include <string_view>
#include <utility>

#include "rules_cc/cc/runfiles/runfiles.h"
#include "tests/test_support.h"

namespace fs = std::filesystem;
using grep_tests::exit_status;
using grep_tests::for_command_interpreter;
using grep_tests::shell_quote;
using grep_tests::temp_dir;
using rules_cc::cc::runfiles::Runfiles;

namespace {

[[noreturn]] void die(const std::string& what) {
  std::cerr << "run_grep_test: " << what << "\n";
  std::exit(2);
}

std::string env_or_empty(const char* name) {
  const char* value = std::getenv(name);
  return value == nullptr ? std::string() : std::string(value);
}

void set_env(const std::string& name, const std::string& value) {
#ifdef _WIN32
  if (_putenv_s(name.c_str(), value.c_str()) != 0) die("cannot set " + name);
#else
  if (setenv(name.c_str(), value.c_str(), 1) != 0) die("cannot set " + name);
#endif
}

void unset_env(const char* name) {
#ifdef _WIN32
  _putenv_s(name, "");
#else
  unsetenv(name);
#endif
}

// Forward slashes everywhere: the values end up in environment variables read
// by a POSIX shell, which on Windows is MSYS2 and understands `C:/...`.
std::string generic(const fs::path& path) { return path.generic_string(); }

// The variables tests/envvar-check refuses to run with (TERM, LS_COLORS,
// POSIXLY_CORRECT, ...). Kept in step with that file. TMPDIR is set again
// below, deliberately after this pass.
constexpr const char* kPerturbingVars[] = {
    "_POSIX2_VERSION", "_STDBUF_E",       "_STDBUF_I",     "_STDBUF_O",
    "BASH_ENV",        "BLOCKSIZE",       "BLOCK_SIZE",    "CDPATH",
    "COLUMNS",         "DF_BLOCK_SIZE",   "DU_BLOCK_SIZE", "ENV",
    "LANGUAGE",        "LS_BLOCK_SIZE",   "LS_COLORS",     "OMP_NUM_THREADS",
    "POSIXLY_CORRECT", "QUOTING_STYLE",   "SIMPLE_BACKUP_SUFFIX",
    "TABSIZE",         "TERM",            "COLORTERM",     "TIME_STYLE",
    "TMPDIR",          "VERSION_CONTROL",
};

// configure probes locales with gt_LOCALE_FR / gt_LOCALE_FR_UTF8, but locale
// availability is a property of the machine running the test, not the one
// that built grep. setlocale() asks the same question grep itself will ask.
// "none" is what init.cfg treats as "no such locale".
std::string first_working_locale(std::initializer_list<const char*> candidates) {
  std::string found = "none";
  for (const char* candidate : candidates) {
    if (std::setlocale(LC_ALL, candidate) != nullptr) {
      found = candidate;
      break;
    }
  }
  std::setlocale(LC_ALL, "C");
  return found;
}

// The values of `#define NAME "value"` lines in config.h, one pass over the
// file. `help-version` checks `grep --version` against $VERSION and several
// tests print $PACKAGE_BUGREPORT, so both come from the header grep was
// built with.
struct ConfigStrings {
  std::string package_bugreport;
  std::string version;
};

ConfigStrings config_strings(const fs::path& config_h) {
  std::ifstream in(config_h);
  if (!in) die("cannot read " + config_h.string());
  ConfigStrings found;
  const auto take = [](const std::string& line, std::string_view name,
                       std::string& into) {
    const std::string prefix = "#define " + std::string(name) + " \"";
    if (line.compare(0, prefix.size(), prefix) != 0) return;
    const std::size_t end = line.find('"', prefix.size());
    if (end != std::string::npos) into = line.substr(prefix.size(), end - prefix.size());
  };
  std::string line;
  while (std::getline(in, line)) {
    take(line, "PACKAGE_BUGREPORT", found.package_bugreport);
    take(line, "VERSION", found.version);
  }
  if (found.package_bugreport.empty() || found.version.empty()) {
    die("PACKAGE_BUGREPORT or VERSION is not a string define in " +
        config_h.string());
  }
  return found;
}

// Shell scripts we generate. The execute bit only exists on POSIX; MSYS2
// runs a script by its `#!` line regardless.
void write_script(const fs::path& path, std::string_view content) {
  grep_tests::write_file(path.string(), content);
  std::error_code ec;
  fs::permissions(path,
                  fs::perms::owner_exec | fs::perms::group_exec |
                      fs::perms::others_exec,
                  fs::perm_options::add, ec);
}

// Copy a built binary into the staged tree under its own file name (so
// `grep.exe` stays `grep.exe`). Where Bazel materializes a runfiles tree,
// staging the tests/ directory may already have brought a copy over --
// read-only, like every Bazel output -- and copy_file cannot overwrite that
// in place, so remove first.
void stage_binary(const fs::path& from, const fs::path& to) {
  std::error_code ec;
  fs::remove(to, ec);
  if (!ec) fs::copy_file(from, to, ec);
  if (ec) die("cannot stage " + from.filename().string() + ": " + ec.message());
}

// The shell that runs the scripts. POSIX: /bin/sh, as automake would use.
//
// Windows: MSYS2's bash, found the way a person would, since Bazel does not
// forward the client's BAZEL_SH into test actions -- an explicit BAZEL_SH
// (`--test_env=BAZEL_SH=...`), then where the BCR runners (MSYS2 under
// C:\tools) and Git for Windows install it, then PATH. Never System32,
// whose bash.exe is the WSL launcher. Always an absolute path: the value
// doubles as $SHELL for the scripts, and a bare `bash` there is resolved
// against their working directory.
std::string test_shell() {
#ifdef _WIN32
  const std::string configured = env_or_empty("BAZEL_SH");
  if (!configured.empty()) return generic(configured);

  std::error_code ec;
  for (const char* candidate : {"C:/tools/msys64/usr/bin/bash.exe",
                                "C:/msys64/usr/bin/bash.exe",
                                "C:/Program Files/Git/usr/bin/bash.exe"}) {
    if (fs::is_regular_file(candidate, ec)) return candidate;
  }

  const std::string path = env_or_empty("PATH");
  for (std::size_t begin = 0; begin <= path.size();) {
    std::size_t end = path.find(';', begin);
    if (end == std::string::npos) end = path.size();
    if (end > begin) {
      const fs::path dir = path.substr(begin, end - begin);
      std::string lowered = generic(dir);
      for (char& c : lowered) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
      const fs::path candidate = dir / "bash.exe";
      if (lowered.find("/system32") == std::string::npos &&
          lowered.find("/windowsapps") == std::string::npos &&
          fs::is_regular_file(candidate, ec)) {
        return generic(candidate);
      }
    }
    begin = end + 1;
  }
  die("no POSIX shell found for the upstream suite; set BAZEL_SH "
      "(e.g. --test_env=BAZEL_SH=C:/tools/msys64/usr/bin/bash.exe) or "
      "install MSYS2");
#else
  return "/bin/sh";
#endif
}

// Run a command line and return the child's exit status.
int run_command(std::string cmd) {
  const int status = std::system(for_command_interpreter(std::move(cmd)).c_str());
  if (status == -1) die(std::string("system() failed: ") + std::strerror(errno));
  return exit_status(status);
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 6) {
    std::cerr << "usage: run_grep_test GREP INIT_SH GET_MB_CUR_MAX CONFIG_H "
                 "TEST_NAME\n";
    return 2;
  }

  std::string error;
  std::unique_ptr<Runfiles> runfiles(
      Runfiles::CreateForTest(BAZEL_CURRENT_REPOSITORY, &error));
  if (!runfiles) die("cannot initialize runfiles: " + error);
  const auto rlocation = [&runfiles](const char* rlocationpath) {
    const std::string path = runfiles->Rlocation(rlocationpath);
    if (path.empty()) die(std::string("cannot resolve runfile ") + rlocationpath);
    return fs::path(path);
  };
  const fs::path grep = rlocation(argv[1]);
  const fs::path init_sh = rlocation(argv[2]);
  const fs::path get_mb_cur_max = rlocation(argv[3]);
  const fs::path config_h = rlocation(argv[4]);
  const std::string test_name = argv[5];

  const fs::path stage = fs::path(temp_dir()) / "tree";
  const fs::path stage_src = stage / "src";
  const fs::path stage_tests = stage / "tests";

  // init.sh's setup_ does `mktempd_ "$initial_cwd_"` and cds into the
  // result, so only the tests directory itself has to be writable; its
  // contents are read-only to the suite. Every file beside init.sh in the
  // runfiles tree is a `tests/` source (plus this package's own build
  // inputs, which are harmless), so the whole directory is staged rather
  // than tracking per-test inputs.
  std::error_code ec;
  fs::create_directories(stage_src, ec);
  if (ec) die("cannot create " + stage_src.string() + ": " + ec.message());
  fs::copy(init_sh.parent_path(), stage_tests,
           fs::copy_options::recursive | fs::copy_options::overwrite_existing,
           ec);
  if (ec) die("cannot stage tests/: " + ec.message());

  stage_binary(grep, stage_src / grep.filename());
  // get-mb-cur-max is upstream's check_PROGRAMS helper; without it on PATH
  // every multibyte test skips.
  stage_binary(get_mb_cur_max, stage_tests / get_mb_cur_max.filename());

  // Upstream generates egrep/fgrep from src/egrep.sh at install time; the
  // `help-version` test runs whatever `built_programs` advertises.
  write_script(stage_src / "egrep", "#!/bin/sh\nexec grep -E \"$@\"\n");
  write_script(stage_src / "fgrep", "#!/bin/sh\nexec grep -F \"$@\"\n");

  // tests/init.cfg sets stderr_fileno_=9 to match the `9>&2` that automake's
  // TESTS_ENVIRONMENT appends; without it every skip_/fail_ diagnostic dies
  // on a bad file descriptor. Done in the shell, where a descriptor
  // redirection means the same thing on every platform.
  write_script(stage_tests / "run-one.sh",
               "#!/bin/sh\nexec 9>&2\nexec \"$SHELL\" \"./$1\"\n");

  for (const char* var : kPerturbingVars) unset_env(var);

  // Names and order follow m4/locale-fr.m4; the m4 additionally checks the
  // locale's codeset, which is why the UTF-8 list does not include plain
  // `fr_FR`.
#ifdef _WIN32
  set_env("LOCALE_FR", first_working_locale({"French_France.1252"}));
  set_env("LOCALE_FR_UTF8", first_working_locale({"French_France.65001"}));
#else
  set_env("LOCALE_FR", first_working_locale(
                           {"fr_FR", "fr_FR.ISO-8859-1", "fr_FR.ISO8859-1"}));
  set_env("LOCALE_FR_UTF8",
          first_working_locale({"fr_FR.UTF-8", "fr_FR.utf8", "fr.UTF-8"}));
#endif
  const ConfigStrings config = config_strings(config_h);
  set_env("PACKAGE_BUGREPORT", config.package_bugreport);
  set_env("VERSION", config.version);
  const std::string shell = test_shell();
  set_env("AWK", "awk");
  // `tests/version-pcre` and `tests/glibc-infloop` grep this to decide
  // whether an optional feature was compiled in.
  set_env("CONFIG_HEADER", generic(config_h));
  set_env("LC_ALL", "C");
  set_env("MALLOC_PERTURB_", "1");
  set_env("SHELL", shell);
  set_env("TMPDIR", generic(stage));
  set_env("abs_srcdir", generic(stage_tests));
  set_env("abs_top_builddir", generic(stage));
  set_env("abs_top_srcdir", generic(stage));
  set_env("built_programs", "grep egrep fgrep");
  set_env("srcdir", ".");
  set_env("top_srcdir", "..");
  // Only tests/stack-overflow reads this, and only to skip on MidnightBSD.
  set_env("host_triplet", "unknown");
#ifdef _WIN32
  constexpr char kPathSeparator = ';';
#else
  constexpr char kPathSeparator = ':';
#endif
  set_env("PATH", generic(stage_src) + kPathSeparator + env_or_empty("PATH"));

  fs::current_path(stage_tests, ec);
  if (ec) die("cannot enter " + stage_tests.string() + ": " + ec.message());

  const int rc = run_command(shell_quote(shell) + " ./run-one.sh " +
                             shell_quote(test_name));

  // Upstream uses exit 77 for "not applicable on this machine" -- almost
  // always a missing locale, or an expensive test that is off by default.
  // Bazel has no runtime-skip status, so report it loudly and pass.
  if (rc == 77) {
    std::cout << "SKIPPED: " << test_name
              << " requested a skip (exit 77); see the log above.\n";
    return 0;
  }
  return rc;
}
