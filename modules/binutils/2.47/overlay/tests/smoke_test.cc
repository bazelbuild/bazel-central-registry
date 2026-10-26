// Smoke test for the programs this module builds.
//
// Upstream's testsuites are DejaGnu (runtest) and out of reach here, so
// this exercises the toolchain end to end on every platform the module
// builds for: each program reports the version this release carries, the
// assembler turns a target-neutral source into an object, the linker
// relinks it, and the inspection tools read the result.  Nothing here
// depends on the target architecture.
//
// The programs are passed as `name=rlocationpath` arguments; which are
// present depends on what the top-level configure builds for the platform
// (no as, ld or gprof for Darwin), and the steps that need a missing
// program are skipped.

#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <string>

#include "rules_cc/cc/runfiles/runfiles.h"

namespace fs = std::filesystem;
using rules_cc::cc::runfiles::Runfiles;

namespace {

int failures = 0;
std::map<std::string, std::string> tools;  // name -> quoted path
fs::path log_file;

std::string quote(const std::string& s) {
#ifdef _WIN32
  return "\"" + s + "\"";
#else
  std::string out = "'";
  for (char c : s) {
    out += c == '\'' ? "'\\''" : std::string(1, c);
  }
  return out + "'";
#endif
}

std::string quoted(const fs::path& p) { return quote(p.string()); }

// Runs COMMAND with its output captured and returns the exit status and the
// output.
std::pair<int, std::string> run(const std::string& command) {
  int status = std::system((command + " > " + quoted(log_file) + " 2>&1").c_str());
  std::ifstream in(log_file);
  std::stringstream text;
  text << in.rdbuf();
  return {status, text.str()};
}

bool contains(const std::string& haystack, const std::string& needle) {
  return haystack.find(needle) != std::string::npos;
}

// Runs COMMAND, with `{}` standing for the quoted path of the program NAME,
// if that program was given; it must exit 0 and its output must satisfy OK.
// Returns whether it did.  (The program is looked up here, after the
// presence test: `tools[name]` at a call site would insert a missing name.)
bool check(const std::string& name, const std::string& command,
           const std::function<bool(const std::string&)>& ok = [](const std::string&) { return true; }) {
  auto tool = tools.find(name);
  if (tool == tools.end()) {
    return false;
  }
  std::string line = command;
  line.replace(line.find("{}"), 2, tool->second);
  auto [status, out] = run(line);
  if (status == 0 && ok(out)) {
    return true;
  }
  std::cerr << "FAIL: " << name << ": status " << status << "\n" << out;
  ++failures;
  return false;
}

std::function<bool(const std::string&)> prints(const std::string& needle) {
  return [needle](const std::string& out) { return contains(out, needle); };
}

std::function<bool(const std::string&)> creates(const fs::path& file) {
  return [file](const std::string&) { return fs::exists(file); };
}

}  // namespace

int main(int argc, char** argv) {
  std::string error;
  std::unique_ptr<Runfiles> runfiles(Runfiles::Create(argv[0], &error));
  if (!runfiles) {
    std::cerr << "runfiles: " << error << "\n";
    return 1;
  }
  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    auto eq = arg.find('=');
    std::string path = eq == std::string::npos ? "" : runfiles->Rlocation(arg.substr(eq + 1));
    if (path.empty() || !fs::exists(path)) {
      std::cerr << "missing program: " << arg << "\n";
      return 1;
    }
    tools[arg.substr(0, eq)] = quote(path);
  }

  const char* tmpdir = std::getenv("TEST_TMPDIR");
  fs::path work = tmpdir ? fs::path(tmpdir) / "smoke" : fs::temp_directory_path() / "binutils-smoke";
  fs::remove_all(work);
  fs::create_directories(work);
  log_file = work / "out.txt";

  // Every program prints the PKGVERSION and this release's version string;
  // development.sh ships `development=true`, so the date is part of it.
  for (const auto& entry : tools) {
    check(entry.first, "{} --version", prints("(GNU Binutils) 2.47.20260726"));
  }

  // A source every target assembles: one data byte and nothing else.
  fs::path source = work / "data.s";
  std::ofstream(source) << "\t.data\n\t.byte 1\n";
  fs::path object = work / "data.o";
  fs::path relinked = work / "relinked.o";
  fs::path archive = work / "libdata.a";

  // Without an assembler there is no object to inspect; the --version runs
  // above are what this platform can check.
  if (!check("as", "{} -o " + quoted(object) + " " + quoted(source), creates(object))) {
    if (failures == 0) {
      std::cout << "ok: " << tools.size() << " programs, no assembler to go further\n";
    }
    return failures == 0 ? 0 : 1;
  }
  check("ld", "{} -r -o " + quoted(relinked) + " " + quoted(object), creates(relinked));
  fs::path inspected = fs::exists(relinked) ? relinked : object;

  check("objdump", "{} -h " + quoted(inspected), prints(".data"));
  check("size", "{} " + quoted(inspected), prints("text"));
  if (check("ar", "{} rc " + quoted(archive) + " " + quoted(object), creates(archive))) {
    check("ar", "{} t " + quoted(archive), prints("data.o"));
    check("ranlib", "{} " + quoted(archive));
  }
  // The object defines no symbols; nm says so on stderr and exits 0.
  check("nm", "{} " + quoted(inspected));
  check("objcopy", "{} " + quoted(inspected) + " " + quoted(work / "copied.o"), creates(work / "copied.o"));
  check("strip", "{} -o " + quoted(work / "stripped.o") + " " + quoted(inspected), creates(work / "stripped.o"));
  check("strings", "{} -n 1 " + quoted(source), prints(".data"));
  check("c++filt", "echo _ZN3foo3barEv | {}", prints("foo::bar()"));
  // readelf is ELF-only; the object is ELF whenever the target's default
  // format is, which objdump's file header tells us.
  bool elf = false;
  check("objdump", "{} -f " + quoted(inspected), [&elf](const std::string& out) { return elf = contains(out, "elf"), true; });
  if (elf) {
    check("readelf", "{} -S " + quoted(inspected), prints(".data"));
  }
  // There is no line information, so the answer is "??" in one of its
  // format-dependent spellings; the exit status is what matters.
  check("addr2line", "{} -e " + quoted(inspected) + " 0", [](const std::string& out) { return !out.empty(); });

  if (failures == 0) {
    std::cout << "ok: " << tools.size() << " programs\n";
  }
  return failures == 0 ? 0 : 1;
}
