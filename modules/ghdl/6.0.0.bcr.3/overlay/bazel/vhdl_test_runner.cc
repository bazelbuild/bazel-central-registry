#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#ifndef _WIN32
#include <unistd.h>
#endif

#include "rules_cc/cc/runfiles/runfiles.h"

namespace fs = std::filesystem;
using rules_cc::cc::runfiles::Runfiles;

int main(int argc, char *argv[]) {
  std::string error;
  auto runfiles = std::unique_ptr<Runfiles>(Runfiles::CreateForTest(&error));
  if (!runfiles) {
    runfiles.reset(Runfiles::Create(argv[0], &error));
  }
  if (!runfiles) {
    std::cerr << "runfiles error: " << error << "\n";
    return 1;
  }

  const char *args_rloc = std::getenv("VHDL_TEST_ARGS_RLOCATIONPATH");
  if (!args_rloc) {
    std::cerr << "VHDL_TEST_ARGS_RLOCATIONPATH not set\n";
    return 1;
  }

  std::string args_path = runfiles->Rlocation(args_rloc);
  if (args_path.empty()) {
    std::cerr << "cannot resolve args file: " << args_rloc << "\n";
    return 1;
  }

  std::ifstream args_file(args_path);
  if (!args_file) {
    std::cerr << "cannot open args file: " << args_path << "\n";
    return 1;
  }

  // Parse args file: key=value lines.
  std::string ghdl_rloc, entity, prefix_rloc;
  std::vector<std::string> flags;
  std::vector<std::string> src_rlocs;

  std::string line;
  while (std::getline(args_file, line)) {
    if (line.empty() || line[0] == '#') continue;
    auto eq = line.find('=');
    if (eq == std::string::npos) continue;
    auto key = line.substr(0, eq);
    auto val = line.substr(eq + 1);
    if (key == "ghdl") ghdl_rloc = val;
    else if (key == "entity") entity = val;
    else if (key == "prefix") prefix_rloc = val;
    else if (key == "flag") flags.push_back(val);
    else if (key == "src") src_rlocs.push_back(val);
  }

  if (ghdl_rloc.empty() || entity.empty() || src_rlocs.empty()) {
    std::cerr << "args file missing required fields\n";
    return 1;
  }

  std::string ghdl = runfiles->Rlocation(ghdl_rloc);
  if (ghdl.empty()) {
    std::cerr << "cannot resolve ghdl: " << ghdl_rloc << "\n";
    return 1;
  }

  std::string prefix;
  if (!prefix_rloc.empty()) {
    prefix = runfiles->Rlocation(prefix_rloc);
  }

  std::vector<std::string> srcs;
  for (auto &rloc : src_rlocs) {
    auto p = runfiles->Rlocation(rloc);
    if (p.empty()) {
      std::cerr << "cannot resolve src: " << rloc << "\n";
      return 1;
    }
    srcs.push_back(p);
  }

  auto workdir = fs::temp_directory_path() /
                 ("ghdl_test_" + std::to_string(getpid()));
  fs::create_directories(workdir);

  std::string env_prefix;
  if (!prefix.empty()) env_prefix = "GHDL_PREFIX=" + prefix + " ";

  // Analyze each source file.
  for (auto &src : srcs) {
    std::string cmd = env_prefix + ghdl + " -a";
    for (auto &f : flags) cmd += " " + f;
    cmd += " --workdir=" + workdir.string() + " " + src;
    if (std::system(cmd.c_str()) != 0) {
      fs::remove_all(workdir);
      return 1;
    }
  }

  // Elaborate and simulate.
  std::string cmd = env_prefix + ghdl + " --elab-run";
  for (auto &f : flags) cmd += " " + f;
  cmd += " --workdir=" + workdir.string() + " " + entity;
  int rc = std::system(cmd.c_str());
  fs::remove_all(workdir);
  return rc == 0 ? 0 : 1;
}
