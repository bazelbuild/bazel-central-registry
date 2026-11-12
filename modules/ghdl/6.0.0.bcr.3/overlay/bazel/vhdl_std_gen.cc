#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#ifdef _WIN32
#include <process.h>
#else
#include <unistd.h>
#endif

namespace fs = std::filesystem;

static int preprocess(int argc, char *argv[]) {
  std::string std_ver, input, output;
  for (int i = 0; i < argc; i++) {
    if (std::strncmp(argv[i], "--std=", 6) == 0)
      std_ver = argv[i] + 6;
    else if (std::strncmp(argv[i], "--input=", 8) == 0)
      input = argv[i] + 8;
    else if (std::strncmp(argv[i], "--output=", 9) == 0)
      output = argv[i] + 9;
  }
  if (std_ver.empty() || input.empty() || output.empty()) {
    std::cerr << "usage: vhdl_std_gen preprocess --std=VER --input=FILE "
                 "--output=FILE\n";
    return 1;
  }

  // Determine which markers to comment out and which blocks to handle.
  // Line markers: lines ending with the marker get "  --" prepended.
  // Block markers: lines between START and END markers get "--" prepended.
  // Delete markers: lines between START and END are removed entirely.
  struct {
    const char *line_comment;  // comment lines containing this
    const char *block_start;   // start of block to comment
    const char *block_end;
    const char *del_start;  // start of block to delete
    const char *del_end;
  } rules[] = {
      // V87: comment --!V87, --V08; block-comment !V87, V08
      {"--!V87", "--START-!V87", "--END-!V87", nullptr, nullptr},
      {"--V08", "--START-V08", "--END-V08", nullptr, nullptr},
      // V93: comment --V87, --V08; block-comment V08
      {"--V87", nullptr, nullptr, nullptr, nullptr},
      // V08: comment --V87, --!V08; block-comment !V08; delete V19
      {"--!V08", "--START-!V08", "--END-!V08", nullptr, nullptr},
      {nullptr, nullptr, nullptr, "--START-V19", "--END-V19"},
  };

  // V19: comment --V87, --!V19; block-comment !V19; strip V19 markers
  // "strip" means delete the START/END lines but keep content between them.
  struct {
    const char *strip_start;
    const char *strip_end;
  } strip_rules[] = {
      {"--START-V19", "--END-V19"},
  };

  // Select which rules apply based on std version.
  std::vector<int> active;
  std::vector<int> active_strips;
  if (std_ver == "87") {
    active = {0, 1};
  } else if (std_ver == "93") {
    active = {2, 1};  // --V87 (line), --V08 (line + block)
  } else if (std_ver == "08") {
    active = {2, 3, 4};  // --V87 (line), --!V08 (line + block), V19 (delete)
  } else if (std_ver == "19") {
    // V19: comment --V87 lines, comment --!V19 lines,
    // block-comment !V19 blocks, strip V19 marker lines.
    active = {2};  // --V87 (line)
    // Add V19-specific rules inline:
    rules[3] = {"--!V19", "--START-!V19", "--END-!V19", nullptr, nullptr};
    active.push_back(3);
    active_strips = {0};
  } else {
    std::cerr << "unknown std version: " << std_ver << "\n";
    return 1;
  }

  std::ifstream in(input);
  if (!in) {
    std::cerr << "cannot open input: " << input << "\n";
    return 1;
  }

  if (auto parent = fs::path(output).parent_path(); !parent.empty())
    fs::create_directories(parent);

  std::ofstream out(output);
  if (!out) {
    std::cerr << "cannot open output: " << output << "\n";
    return 1;
  }

  std::string line;
  bool in_comment_block = false;
  bool in_delete_block = false;
  while (std::getline(in, line)) {
    // Check block end markers first.
    bool handled = false;
    for (int idx : active) {
      auto &r = rules[idx];
      if (in_delete_block && r.del_end && line.find(r.del_end) != std::string::npos) {
        in_delete_block = false;
        handled = true;
        break;
      }
      if (in_comment_block && r.block_end &&
          line.find(r.block_end) != std::string::npos) {
        out << "--" << line << "\n";
        in_comment_block = false;
        handled = true;
        break;
      }
    }
    if (handled) continue;

    if (in_delete_block) continue;
    if (in_comment_block) {
      out << "--" << line << "\n";
      continue;
    }

    // Check strip markers (delete the marker line, keep content).
    for (int idx : active_strips) {
      auto &s = strip_rules[idx];
      if (line.find(s.strip_start) != std::string::npos ||
          line.find(s.strip_end) != std::string::npos) {
        handled = true;
        break;
      }
    }
    if (handled) continue;

    // Check block start markers.
    for (int idx : active) {
      auto &r = rules[idx];
      if (r.del_start && line.find(r.del_start) != std::string::npos) {
        in_delete_block = true;
        handled = true;
        break;
      }
      if (r.block_start && line.find(r.block_start) != std::string::npos) {
        out << "--" << line << "\n";
        in_comment_block = true;
        handled = true;
        break;
      }
    }
    if (handled) continue;

    // Check line markers.
    bool commented = false;
    for (int idx : active) {
      auto &r = rules[idx];
      if (r.line_comment && line.find(r.line_comment) != std::string::npos) {
        out << "  --" << line << "\n";
        commented = true;
        break;
      }
    }
    if (!commented) out << line << "\n";
  }
  return 0;
}

static int compile_lib(int argc, char *argv[]) {
  std::string ghdl, workdir, lib_path;
  std::vector<std::string> flags;
  std::vector<std::string> files;

  for (int i = 0; i < argc; i++) {
    if (std::strncmp(argv[i], "--ghdl=", 7) == 0)
      ghdl = argv[i] + 7;
    else if (std::strncmp(argv[i], "--workdir=", 10) == 0)
      workdir = argv[i] + 10;
    else if (std::strncmp(argv[i], "--lib-path=", 11) == 0)
      lib_path = argv[i] + 11;
    else if (std::strncmp(argv[i], "--flag=", 7) == 0)
      flags.emplace_back(argv[i] + 7);
    else if (argv[i][0] != '-')
      files.emplace_back(argv[i]);
  }

  if (ghdl.empty() || workdir.empty()) {
    std::cerr << "usage: vhdl_std_gen compile-lib --ghdl=PATH "
                 "--workdir=DIR [--flag=F]... [--lib-path=P] file...\n";
    return 1;
  }

  auto abs_ghdl = fs::absolute(ghdl);
  fs::create_directories(workdir);

  // Compute relative paths from workdir to files using the logical
  // (execroot-relative) paths, not absolute sandbox paths.
  auto rel_from_workdir = [&](const std::string &target) -> std::string {
    return fs::relative(fs::path(target), fs::path(workdir)).string();
  };

  auto cwd = fs::current_path();
  fs::current_path(workdir);

  for (auto &f : files) {
    std::string cmd = abs_ghdl.string() + " -a";
    for (auto &fl : flags) cmd += " " + fl;
    if (!lib_path.empty())
      cmd += " -P" + rel_from_workdir(lib_path);
    cmd += " " + rel_from_workdir(f);
    int rc = std::system(cmd.c_str());
    if (rc != 0) {
      std::cerr << "ghdl compile failed: " << cmd << "\n";
      fs::current_path(cwd);
      return 1;
    }
  }
  fs::current_path(cwd);
  return 0;
}

static int test_cmd(int argc, char *argv[]) {
  std::string ghdl, entity, prefix;
  std::vector<std::string> flags;
  std::vector<std::string> files;

  for (int i = 0; i < argc; i++) {
    if (std::strncmp(argv[i], "--ghdl=", 7) == 0)
      ghdl = argv[i] + 7;
    else if (std::strncmp(argv[i], "--entity=", 9) == 0)
      entity = argv[i] + 9;
    else if (std::strncmp(argv[i], "--prefix=", 9) == 0)
      prefix = argv[i] + 9;
    else if (std::strncmp(argv[i], "--flag=", 7) == 0)
      flags.emplace_back(argv[i] + 7);
    else if (argv[i][0] != '-')
      files.emplace_back(argv[i]);
  }

  if (ghdl.empty() || entity.empty()) {
    std::cerr << "usage: vhdl_std_gen test --ghdl=PATH --entity=NAME "
                 "[--prefix=DIR] [--flag=F]... file...\n";
    return 1;
  }

  auto workdir = fs::temp_directory_path() / ("ghdl_test_" + std::to_string(getpid()));
  fs::create_directories(workdir);

  std::string env_prefix;
  if (!prefix.empty()) env_prefix = "GHDL_PREFIX=" + prefix + " ";

  for (auto &f : files) {
    std::string cmd = env_prefix + ghdl + " -a";
    for (auto &fl : flags) cmd += " " + fl;
    cmd += " --workdir=" + workdir.string();
    cmd += " " + f;
    int rc = std::system(cmd.c_str());
    if (rc != 0) {
      fs::remove_all(workdir);
      return 1;
    }
  }

  std::string cmd = env_prefix + ghdl + " --elab-run";
  for (auto &fl : flags) cmd += " " + fl;
  cmd += " --workdir=" + workdir.string();
  cmd += " " + entity;
  int rc = std::system(cmd.c_str());
  fs::remove_all(workdir);
  return rc == 0 ? 0 : 1;
}

static int dispatch(const std::string &cmd, int argc, char *argv[]) {
  if (cmd == "preprocess") return preprocess(argc, argv);
  if (cmd == "compile-lib") return compile_lib(argc, argv);
  if (cmd == "test") return test_cmd(argc, argv);
  std::cerr << "unknown command: " << cmd << "\n";
  return 1;
}

int main(int argc, char *argv[]) {
  if (argc < 2) {
    std::cerr << "usage: vhdl_std_gen <preprocess|compile-lib|test> ...\n";
    return 1;
  }

  // Split on "++" to support chained subcommands.
  int i = 1;
  while (i < argc) {
    std::string cmd = argv[i];
    i++;
    int start = i;
    while (i < argc && std::string(argv[i]) != "++") i++;
    int rc = dispatch(cmd, i - start, argv + start);
    if (rc != 0) return rc;
    if (i < argc) i++;  // skip "++"
  }
  return 0;
}
