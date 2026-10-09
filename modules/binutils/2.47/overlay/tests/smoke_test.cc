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

std::string Quote(const std::string& s) {
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

std::string Q(const fs::path& p) { return Quote(p.string()); }

// Runs COMMAND with its output captured and returns the exit status and the
// output.
std::pair<int, std::string> Run(const std::string& command) {
  int status = std::system((command + " > " + Q(log_file) + " 2>&1").c_str());
  std::ifstream in(log_file);
  std::stringstream text;
  text << in.rdbuf();
  return {status, text.str()};
}

bool Contains(const std::string& haystack, const std::string& needle) {
  return haystack.find(needle) != std::string::npos;
}

// Runs COMMAND if the program NAME was given; it must exit 0 and its output
// must satisfy OK.  Returns whether it did.
bool Check(const std::string& name, const std::string& command,
           const std::function<bool(const std::string&)>& ok = [](const std::string&) { return true; }) {
  if (!tools.count(name)) {
    return false;
  }
  auto [status, out] = Run(command);
  if (status == 0 && ok(out)) {
    return true;
  }
  std::cerr << "FAIL: " << name << ": status " << status << "\n" << out;
  ++failures;
  return false;
}

std::function<bool(const std::string&)> Prints(const std::string& needle) {
  return [needle](const std::string& out) { return Contains(out, needle); };
}

std::function<bool(const std::string&)> Creates(const fs::path& file) {
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
    tools[arg.substr(0, eq)] = Quote(path);
  }

  const char* tmpdir = std::getenv("TEST_TMPDIR");
  fs::path work = tmpdir ? fs::path(tmpdir) / "smoke" : fs::temp_directory_path() / "binutils-smoke";
  fs::remove_all(work);
  fs::create_directories(work);
  log_file = work / "out.txt";

  // Every program prints the PKGVERSION and this release's version string;
  // development.sh ships `development=true`, so the date is part of it.
  for (const auto& [name, path] : tools) {
    Check(name, path + " --version", Prints("(GNU Binutils) 2.47.20260726"));
  }

  // A source every target assembles: one data byte and nothing else.
  fs::path source = work / "data.s";
  std::ofstream(source) << "\t.data\n\t.byte 1\n";
  fs::path object = work / "data.o";
  fs::path relinked = work / "relinked.o";
  fs::path archive = work / "libdata.a";

  // Without an assembler there is no object to inspect; the --version runs
  // above are what this platform can check.
  if (!Check("as", tools["as"] + " -o " + Q(object) + " " + Q(source), Creates(object))) {
    return failures == 0 ? 0 : 1;
  }
  Check("ld", tools["ld"] + " -r -o " + Q(relinked) + " " + Q(object), Creates(relinked));
  fs::path inspected = fs::exists(relinked) ? relinked : object;

  Check("objdump", tools["objdump"] + " -h " + Q(inspected), Prints(".data"));
  Check("size", tools["size"] + " " + Q(inspected), Prints("text"));
  if (Check("ar", tools["ar"] + " rc " + Q(archive) + " " + Q(object), Creates(archive))) {
    Check("ar", tools["ar"] + " t " + Q(archive), Prints("data.o"));
    Check("ranlib", tools["ranlib"] + " " + Q(archive));
  }
  // The object defines no symbols; nm says so on stderr and exits 0.
  Check("nm", tools["nm"] + " " + Q(inspected));
  Check("objcopy", tools["objcopy"] + " " + Q(inspected) + " " + Q(work / "copied.o"), Creates(work / "copied.o"));
  Check("strip", tools["strip"] + " -o " + Q(work / "stripped.o") + " " + Q(inspected), Creates(work / "stripped.o"));
  Check("strings", tools["strings"] + " -n 1 " + Q(source), Prints(".data"));
  Check("c++filt", "echo _ZN3foo3barEv | " + tools["c++filt"], Prints("foo::bar()"));
  // readelf is ELF-only; the object is ELF whenever the target's default
  // format is, which objdump's file header tells us.
  if (Check("objdump", tools["objdump"] + " -f " + Q(inspected)) && Contains(Run(tools["objdump"] + " -f " + Q(inspected)).second, "elf")) {
    Check("readelf", tools["readelf"] + " -S " + Q(inspected), Prints(".data"));
  }
  // There is no line information, so the answer is "??" in one of its
  // format-dependent spellings; the exit status is what matters.
  Check("addr2line", tools["addr2line"] + " -e " + Q(inspected) + " 0", [](const std::string& out) { return !out.empty(); });

  if (failures == 0) {
    std::cout << "ok: " << tools.size() << " programs\n";
  }
  return failures == 0 ? 0 : 1;
}
