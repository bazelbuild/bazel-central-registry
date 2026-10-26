// Smoke test for the `cpio` binary this module builds.
//
// `:upstream_testsuite` is the thorough check, but it is a bash script and so
// runs nowhere Windows.  This covers the two things worth knowing on every
// platform the module builds for: the binary reports its version, and a `newc`
// archive of a fixed tree round trips through copy-out and copy-in with its
// member list intact.
//
// The tree is built by the test under $TEST_TMPDIR rather than shipped as
// `data`, so `cpio` is the only program the test runs -- no find, sort, cp or
// diff -- and nothing has to be copied out of the runfiles to dodge symlinks.
// That is also what lets the same test run on Windows.
//
// Note that the archive bytes themselves are deliberately not goldened.
// `--reproducible` is `--ignore-devno --renumber-inodes`; it zeroes device
// numbers and renumbers inodes, but the `newc` header still carries each
// member's mtime, which is not stable across machines.

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "rules_cc/cc/runfiles/runfiles.h"

namespace fs = std::filesystem;
using rules_cc::cc::runfiles::Runfiles;

namespace {

// A directory, a nested path and a zero-length file, so the member list
// exercises more than a flat listing.  A null `content` marks a directory.
// This doubles as the list fed to copy-out on stdin: parents come first, which
// is what `find` would have produced.
struct Entry {
  const char* path;
  const char* content;
};

const Entry TREE[] = {
    {"testdata", nullptr},
    {"testdata/a.txt", "alpha\n"},
    {"testdata/empty.txt", ""},
    {"testdata/sub", nullptr},
    {"testdata/sub/b.txt", "bee\n"},
};

const char VERSION[] =
    "cpio (GNU cpio) 2.15\n"
    "Copyright (C) 2024 Free Software Foundation, Inc.\n"
    "License GPLv3+: GNU GPL version 3 or later "
    "<https://gnu.org/licenses/gpl.html>.\n"
    "This is free software: you are free to change and redistribute it.\n"
    "There is NO WARRANTY, to the extent permitted by law.\n"
    "\n"
    "Written by Phil Nelson, David MacKenzie, John Oleynick,\n"
    "and Sergey Poznyakoff.\n";

int fail(const std::string& message) {
  std::cerr << "smoke_test: " << message << "\n";
  return 1;
}

void write_file(const fs::path& path, const std::string& content) {
  std::ofstream out(path, std::ios::binary);
  out << content;
}

std::string read_file(const fs::path& path) {
  std::ifstream in(path, std::ios::binary);
  std::ostringstream buffer;
  buffer << in.rdbuf();
  std::string text = buffer.str();
  // cpio writes "\n", but the Windows CRT turns that into "\r\n" on the way
  // through a redirected stdout.  Compare the Unix form everywhere.
  text.erase(std::remove(text.begin(), text.end(), '\r'), text.end());
  return text;
}

std::string quote(const fs::path& path) { return "\"" + path.string() + "\""; }

// `system()` hands the string to /bin/sh, or on Windows to `cmd /c`.  cmd
// strips the outermost pair of quotes off the whole command line before it
// parses it, so a command that opens with a quoted program path needs a second
// pair wrapped around everything.
int run(const std::string& command) {
#ifdef _WIN32
  return std::system(("\"" + command + "\"").c_str());
#else
  return std::system(command.c_str());
#endif
}

// One member, rendered the same way from the fixture and from what copy-in
// actually produced.  Contents are chomped so a member never spans two lines of
// the failure message.
std::string describe(const std::string& path, const std::string* content) {
  if (content == nullptr) return "dir  " + path;
  std::string text = *content;
  while (!text.empty() && text.back() == '\n') text.pop_back();
  return "file " + path + " " + text;
}

int run_test(const char* cpio_rlocationpath) {
  std::string error;
  const std::unique_ptr<Runfiles> runfiles(
      Runfiles::CreateForTest(BAZEL_CURRENT_REPOSITORY, &error));
  if (runfiles == nullptr) return fail("could not locate runfiles: " + error);

  const fs::path cpio = runfiles->Rlocation(cpio_rlocationpath);
  if (cpio.empty()) {
    return fail(std::string("not in the runfiles: ") + cpio_rlocationpath);
  }

  const char* test_tmpdir = std::getenv("TEST_TMPDIR");
  if (test_tmpdir == nullptr) return fail("TEST_TMPDIR is not set");
  const fs::path work = fs::path(test_tmpdir) / "smoke";
  fs::remove_all(work);
  fs::create_directories(work);

  // --version.
  const fs::path version = work / "version.txt";
  if (run(quote(cpio) + " --version > " + quote(version)) != 0) {
    return fail("cpio --version exited nonzero");
  }
  const std::string actual_version = read_file(version);
  if (actual_version != VERSION) {
    return fail("--version output changed:\n" + actual_version);
  }

  // Lay out the fixture and the list of names to archive.
  const fs::path src = work / "src";
  fs::create_directories(src);
  std::string members;
  std::vector<std::string> expected;
  for (const Entry& entry : TREE) {
    if (entry.content == nullptr) {
      fs::create_directories(src / entry.path);
      expected.push_back(describe(entry.path, nullptr));
    } else {
      const std::string content = entry.content;
      write_file(src / entry.path, content);
      expected.push_back(describe(entry.path, &content));
    }
    members += std::string(entry.path) + "\n";
  }
  const fs::path member_list = work / "members.txt";
  write_file(member_list, members);

  // This is the command line the module exists to make hermetic.
  const fs::path archive = work / "testdata.cpio";
  fs::current_path(src);
  if (run(quote(cpio) + " --reproducible --quiet -o -H newc < " +
          quote(member_list) + " > " + quote(archive)) != 0) {
    return fail("copy-out exited nonzero");
  }

  // ... and back again.
  const fs::path out = work / "out";
  fs::create_directories(out);
  fs::current_path(out);
  if (run(quote(cpio) + " --quiet -i -d < " + quote(archive)) != 0) {
    return fail("copy-in exited nonzero");
  }

  std::vector<std::string> actual;
  for (const fs::directory_entry& entry :
       fs::recursive_directory_iterator(out)) {
    const std::string path =
        entry.path().lexically_relative(out).generic_string();
    if (entry.is_directory()) {
      actual.push_back(describe(path, nullptr));
    } else {
      const std::string content = read_file(entry.path());
      actual.push_back(describe(path, &content));
    }
  }

  // `recursive_directory_iterator` has no defined order, so compare as sets.
  std::sort(actual.begin(), actual.end());
  std::sort(expected.begin(), expected.end());
  if (actual != expected) {
    std::ostringstream message;
    message << "member list did not survive the round trip\nexpected:\n";
    for (const std::string& line : expected) message << "  " << line << "\n";
    message << "actual:\n";
    for (const std::string& line : actual) message << "  " << line << "\n";
    return fail(message.str());
  }

  return 0;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 2) {
    return fail("usage: smoke_test <rlocationpath of the cpio binary>");
  }
  return run_test(argv[1]);
}
