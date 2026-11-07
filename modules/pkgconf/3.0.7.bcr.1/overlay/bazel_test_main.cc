// bazel_test_main.cc -- runfiles-aware entry point for tests/test-runner.c.
//
// SPDX-License-Identifier: pkgconf
//
// Not upstream. meson hands test-runner two absolute directories. Under
// Bazel those are runfiles, and Bazel only
// promises to materialize a runfiles *tree* on Linux and macOS; on Windows a
// test is handed a manifest instead, and Bazel's own Windows test wrapper falls
// back to Rlocation even to find the test binary (tools/test/windows/tw.cc).
// test-runner opendir()s the suite and realpath()s the fixtures, and knows
// nothing about manifests, so the directories have to be produced here for the
// tests to run without `--enable_runfiles`:
//
//   tree      $RUNFILES_DIR/<dir> exists already; hand both over untouched.
//   manifest  rebuild them under $TEST_TMPDIR from <filelist>, which utils.bzl
//             writes from the same glob that puts the files in the runfiles.
//             Rebuilding rather than pointing at the unpacked tarball is what
//             keeps the BUILD file's `exclude` honoured.
//
// The tools are found by prepending their directory to PATH rather than by
// passing `--tool-dir`, which run_tool() only uses to prefix the tool name
// before handing it to popen(). A PATH lookup keeps that string free of
// anything a shell would have to expand, and lets PATHEXT supply the `.exe`
// suffix the `.test` files omit.

#include <sys/stat.h>
#include <sys/types.h>

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <memory>
#include <string>

#ifdef _WIN32
#include <direct.h>
#define MKDIR(path) _mkdir(path)
#define PATH_LIST_SEPARATOR ';'
#else
#define MKDIR(path) mkdir(path, 0755)
#define PATH_LIST_SEPARATOR ':'
#endif

#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

// tests/test-runner.c's main(), renamed by -Dmain= so it can be called here.
extern "C" int pkgconf_test_runner_main(int argc, char *argv[]);

namespace {

void die(const std::string &message) {
  std::fprintf(stderr, "bazel_test_main: %s\n", message.c_str());
  std::exit(1);
}

bool is_dir(const std::string &path) {
  struct stat st;
  return stat(path.c_str(), &st) == 0 && (st.st_mode & S_IFMT) == S_IFDIR;
}

// Rlocation reports a path without checking it -- with a runfiles directory
// known it is little more than a join -- so existence is confirmed separately.
std::string find_dir(const Runfiles &runfiles, const std::string &rlocation) {
  const std::string path = runfiles.Rlocation(rlocation);
  return !path.empty() && is_dir(path) ? path : std::string();
}

std::string find_file(const Runfiles &runfiles, const std::string &rlocation) {
  const std::string path = runfiles.Rlocation(rlocation);
  if (path.empty()) die("not in the runfiles: " + rlocation);
  return path;
}

// Everything before the first separator of an Rlocation path: the repository
// the rest of it is relative to.
std::string repo_of(const std::string &rlocation) {
  const size_t slash = rlocation.find('/');
  if (slash == std::string::npos) die("not an Rlocation path: " + rlocation);
  return rlocation.substr(0, slash);
}

// The filelist is emitted in glob order, so runs of files share a directory and
// remembering the last one created skips nearly every repeat walk.
void make_dirs(const std::string &path) {
  static std::string last;
  if (path == last) return;

  for (size_t i = path.find('/', 1); i != std::string::npos;
       i = path.find('/', i + 1)) {
    // Intermediate failures are left to the ofstream in copy_file to report: an
    // existing directory is the common case and not an error.
    MKDIR(path.substr(0, i).c_str());
  }
  MKDIR(path.c_str());
  last = path;
}

void copy_file(const std::string &src, const std::string &dst) {
  std::ifstream in(src.c_str(), std::ios::binary);
  if (!in) die("cannot read runfile: " + src);

  std::ofstream out(dst.c_str(), std::ios::binary);
  if (!out) die("cannot write staged runfile: " + dst);

  out << in.rdbuf();
  out.close();
  if (!out) die("short write: " + dst);
}

// Rebuild the subtree the test needs under $TEST_TMPDIR, keeping every file
// exactly where it sits in the tarball. `t/` cases reach up into the fixtures
// with paths like `../../tests/lib-sbom-files/basic.json`, which
// ExpectedStdoutFile resolves against the `.test` file's own directory, so the
// layout is load-bearing and not just tidy.
// https://github.com/pkgconf/pkgconf/blob/pkgconf-3.0.7/tests/test-runner.c#L1335-L1341
std::string stage(const Runfiles &runfiles, const std::string &filelist_path) {
  const char *tmp = std::getenv("TEST_TMPDIR");
  if (tmp == nullptr || *tmp == '\0')
    die("no runfiles tree, and TEST_TMPDIR is unset");

  // Windows spells $TEST_TMPDIR with backslashes; every API used below takes
  // either separator, so normalising once here is enough to let the rest of
  // this file split paths on '/' alone.
  std::string root = std::string(tmp) + "/staged";
  for (char &c : root)
    if (c == '\\') c = '/';

  std::ifstream in(filelist_path.c_str());
  if (!in) die("cannot read the runfiles list: " + filelist_path);

  std::string rlocation;
  bool staged_any = false;
  while (std::getline(in, rlocation)) {
    if (rlocation.empty()) continue;
    // Drop the repository name so the copy is rooted where the tarball is.
    const std::string dst =
        root + "/" + rlocation.substr(repo_of(rlocation).size() + 1);
    make_dirs(dst.substr(0, dst.find_last_of('/')));
    copy_file(find_file(runfiles, rlocation), dst);
    staged_any = true;
  }

  if (!staged_any) die("the runfiles list is empty: " + filelist_path);
  return root;
}

void prepend_to_path(std::string dir) {
#ifdef _WIN32
  // A PATH entry is conventionally spelled with backslashes on Windows.
  for (char &c : dir)
    if (c == '/') c = '\\';
#endif

  const char *old = std::getenv("PATH");
  const std::string value =
      dir + PATH_LIST_SEPARATOR + (old != nullptr ? old : "");

#ifdef _WIN32
  _putenv_s("PATH", value.c_str());
#else
  setenv("PATH", value.c_str(), 1);
#endif
}

// Fixed by the tarball layout, not chosen here.
const char FIXTURES_DIR[] = "tests";

}  // namespace

int main(int argc, char *argv[]) {
  if (argc != 4) {
    std::fprintf(stderr, "usage: %s <filelist> <pkgconf> <suite-dir>\n",
                 argv[0]);
    return 2;
  }
  // The first two arguments are Rlocation paths, expanded by the BUILD file;
  // <suite-dir> is relative to the repository root, e.g. `t/basic`. Which
  // repository that is gets read off the front of <filelist> rather than
  // written down, so this file never names the module.
  const std::string filelist_rlocation = argv[1];
  const std::string repo = repo_of(filelist_rlocation) + "/";

  std::string error;
  const std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
  if (runfiles == nullptr) die("cannot initialise runfiles: " + error);

  std::string fixtures = find_dir(*runfiles, repo + FIXTURES_DIR);
  std::string suite = find_dir(*runfiles, repo + argv[3]);
  if (fixtures.empty() || suite.empty()) {
    const std::string root =
        stage(*runfiles, find_file(*runfiles, filelist_rlocation));
    fixtures = root + "/" + FIXTURES_DIR;
    suite = root + "/" + argv[3];
  }

  // All four tools share a directory, so any one of them locates it.
  const std::string pkgconf = find_file(*runfiles, argv[2]);
  const size_t slash = pkgconf.find_last_of("/\\");
  if (slash == std::string::npos) die("no directory in path: " + pkgconf);
  prepend_to_path(pkgconf.substr(0, slash));

  // test-runner reads argv[pkg_optind] once its option loop is done, so the
  // array has to carry the terminating NULL a real argv would.
  char *runner_argv[] = {argv[0], const_cast<char *>("--test-fixtures"),
                         &fixtures[0], &suite[0], nullptr};
  return pkgconf_test_runner_main(4, runner_argv);
}
