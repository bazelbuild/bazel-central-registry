/// @file vhdl_compile.cc
/// @brief Drive a sequence of `nvc -a` invocations to build a VHDL
///        library.
///
/// Replaces the inline shell command the `vhdl_library` Starlark rule
/// used to emit. With a structured CLI the rule can use
/// `ctx.actions.run` with a `cc_binary` tool, avoiding
/// `ctx.actions.run_shell` and its associated quoting traps.
///
/// Behaviour mirrors `lib/<dir>/Makemodule.am`:
///
/// -# The work directory is created (NVC also creates it on demand,
///    but pre-creating silences the "directory ... is not an NVC
///    library" warning on the first call).
/// -# If `--seed-from DIR` is given, its contents are recursively
///    copied into `--work` before any analyses run. That lets the
///    `std_base → nvc → std` bootstrap split re-use already-built
///    `STANDARD` units without re-analysing them.
/// -# For each `--src FILE`, nvc is invoked with the supplied
///    `--std`, `--work`, and `-L` paths, optionally with
///    `--bootstrap` (for the very first source) and/or `--relaxed`.
///
/// Usage:
/// @code
///   vhdl_compile --nvc NVC --std STD --work DIR
///                [--seed-from DIR] [--bootstrap-first] [--relaxed]
///                [-L PATH]... --src FILE...
/// @endcode
///
/// Subprocess invocation uses platform-specific APIs gated by
/// `#ifdef _WIN32`: `CreateProcessA` on Windows, `posix_spawnp` on
/// POSIX. std::filesystem (C++17) handles the directory copy on every
/// platform.

#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <iostream>
#include <string>
#include <system_error>
#include <unordered_set>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#else
#include <spawn.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
extern char** environ;
#endif

namespace fs = std::filesystem;

namespace {

/// Print a diagnostic to stderr and abort with status 2.
[[noreturn]] void die(const std::string& msg) {
  std::cerr << "vhdl_compile: " << msg << "\n";
  std::exit(2);
}

/// Make @p p writable by its owner. Picks an absolute mode based on
/// the entry type — 0o755 for directories (so we can still cd /
/// enumerate inside) and 0o644 for everything else.
///
/// Uses raw POSIX `chmod()` instead of `std::filesystem::permissions`
/// because libstdc++'s `perm_options::add` has been observed to fail
/// silently on linux-sandbox builds — the destination file ends up
/// with the source's mode bits even after a successful call, leaving
/// nvc's later `open(_NVC_LIB, O_RDWR)` to bounce back EROFS/EACCES.
/// Setting the mode absolutely — rather than ORing in a single bit —
/// sidesteps that whole class of failure.
///
/// On Windows the concept doesn't translate cleanly; we no-op
/// because TreeArtifact inputs aren't marked read-only there anyway.
void make_writable(const fs::path& p, bool is_directory) {
#ifndef _WIN32
  const mode_t mode = is_directory
                          ? (S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH)
                          : (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
  if (chmod(p.c_str(), mode) != 0) {
    // Tolerate symlinks-to-missing and similar — the subsequent file
    // operation will fail loudly enough on its own if the file
    // genuinely stays read-only.
  }
#else
  (void)p;
  (void)is_directory;
#endif
}

/// Recursively copy the contents of @p src (not the directory itself)
/// into @p dst. Replicates `cp -rL SRC/. DST/` — note the `-L`:
/// symbolic links in the source tree are *followed*, and the byte
/// contents land in newly-created regular files inside @p dst.
///
/// Following links matters because Bazel materialises TreeArtifact
/// inputs via symlinks into a read-only sandbox view. `fs::copy` with
/// `copy_options::copy_symlinks` would faithfully recreate those
/// symlinks under @p dst, pointing back at the read-only originals;
/// any subsequent `chmod()` or `open(..., O_RDWR)` would then bounce
/// off the sandbox's input-immutability with EACCES, and nvc's
/// `cannot write to read-only library STD` is exactly that error path.
///
/// By following links we end up with regular files we created and
/// own, so the follow-up `make_writable` calls operate on our own
/// outputs — never on a sandboxed input.
void copy_contents(const fs::path& src, const fs::path& dst) {
  std::error_code ec;
  for (const auto& entry : fs::directory_iterator(src, ec)) {
    if (ec) die("could not list " + src.string() + ": " + ec.message());
    const fs::path target = dst / entry.path().filename();
    fs::copy(entry.path(), target,
             fs::copy_options::recursive |
                 fs::copy_options::overwrite_existing,
             ec);
    if (ec) {
      die("failed to copy " + entry.path().string() + " -> " +
          target.string() + ": " + ec.message());
    }
  }
  make_writable(dst, /*is_directory=*/true);
  for (const auto& entry : fs::recursive_directory_iterator(dst, ec)) {
    if (ec) die("could not walk " + dst.string() + ": " + ec.message());
    make_writable(entry.path(), entry.is_directory());
  }
}

#ifdef _WIN32

/// Quote a single argument for CreateProcessA's command-line string.
/// Follows the algorithm documented at
/// https://learn.microsoft.com/en-us/archive/blogs/twistylittlepassagesallalike/everyone-quotes-command-line-arguments-the-wrong-way
std::string quote_arg_win32(const std::string& arg) {
  if (!arg.empty() &&
      arg.find_first_of(" \t\n\v\"") == std::string::npos) {
    return arg;
  }
  std::string out = "\"";
  for (size_t i = 0; i < arg.size(); ++i) {
    size_t backslashes = 0;
    while (i < arg.size() && arg[i] == '\\') {
      ++backslashes;
      ++i;
    }
    if (i == arg.size()) {
      out.append(backslashes * 2, '\\');
      break;
    } else if (arg[i] == '"') {
      out.append(backslashes * 2 + 1, '\\');
      out.push_back('"');
    } else {
      out.append(backslashes, '\\');
      out.push_back(arg[i]);
    }
  }
  out.push_back('"');
  return out;
}

/// Spawn @p argv via CreateProcessA, wait for completion, return its
/// exit code (or a negative sentinel if the process crashed).
int run_subprocess(const std::vector<std::string>& argv) {
  std::string command_line;
  for (size_t i = 0; i < argv.size(); ++i) {
    if (i > 0) command_line += ' ';
    command_line += quote_arg_win32(argv[i]);
  }

  STARTUPINFOA si{};
  si.cb = sizeof(si);
  PROCESS_INFORMATION pi{};

  // CreateProcessA mutates its lpCommandLine buffer, so make a
  // writable copy.
  std::vector<char> cmd_buf(command_line.begin(), command_line.end());
  cmd_buf.push_back('\0');

  if (!CreateProcessA(argv[0].c_str(), cmd_buf.data(), nullptr, nullptr,
                      FALSE, 0, nullptr, nullptr, &si, &pi)) {
    die("CreateProcess failed for " + argv[0] +
        " (error " + std::to_string(GetLastError()) + ")");
  }

  WaitForSingleObject(pi.hProcess, INFINITE);
  DWORD exit_code = 0;
  GetExitCodeProcess(pi.hProcess, &exit_code);
  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
  return static_cast<int>(exit_code);
}

#else

/// Spawn @p argv via posix_spawnp, wait for completion, return its
/// exit code. Returns 128+signal if the process was killed by a
/// signal (mirroring shell convention).
int run_subprocess(const std::vector<std::string>& argv) {
  std::vector<char*> raw;
  raw.reserve(argv.size() + 1);
  for (const auto& a : argv) raw.push_back(const_cast<char*>(a.c_str()));
  raw.push_back(nullptr);

  pid_t pid = 0;
  const int err =
      posix_spawnp(&pid, raw[0], nullptr, nullptr, raw.data(), environ);
  if (err != 0) {
    die(std::string("posix_spawnp failed for ") + raw[0] + ": " +
        std::strerror(err));
  }

  int status = 0;
  if (waitpid(pid, &status, 0) < 0) {
    die(std::string("waitpid failed: ") + std::strerror(errno));
  }
  if (WIFEXITED(status)) return WEXITSTATUS(status);
  if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
  return 1;
}

#endif

}  // namespace

int main(int argc, char** argv) {
  std::string nvc_path;
  std::string std_arg;
  std::string work;
  std::string seed_from;
  bool bootstrap_first = false;
  bool relaxed = false;
  std::vector<std::string> l_paths;
  std::vector<std::string> srcs;

  for (int i = 1; i < argc; ++i) {
    const std::string flag = argv[i];
    if (flag == "--nvc" && i + 1 < argc) {
      nvc_path = argv[++i];
    } else if (flag == "--std" && i + 1 < argc) {
      std_arg = argv[++i];
    } else if (flag == "--work" && i + 1 < argc) {
      work = argv[++i];
    } else if (flag == "--seed-from" && i + 1 < argc) {
      seed_from = argv[++i];
    } else if (flag == "--bootstrap-first") {
      bootstrap_first = true;
    } else if (flag == "--relaxed") {
      relaxed = true;
    } else if (flag == "-L" && i + 1 < argc) {
      l_paths.push_back(argv[++i]);
    } else if (flag == "--src" && i + 1 < argc) {
      srcs.push_back(argv[++i]);
    } else {
      die("unknown argument: " + flag);
    }
  }

  if (nvc_path.empty()) die("--nvc is required");
  if (std_arg.empty()) die("--std is required");
  if (work.empty()) die("--work is required");

  const fs::path work_path(work);
  std::error_code ec;
  fs::create_directories(work_path, ec);
  if (ec) die("could not mkdir " + work + ": " + ec.message());

  if (!seed_from.empty()) {
    copy_contents(fs::path(seed_from), work_path);
  }

  // The library's own work-dir parent must be in -L so nvc finds STD
  // (and the in-progress library itself) across multi-call sequences.
  // De-dup while preserving order — search order is significant.
  std::vector<std::string> all_l;
  std::unordered_set<std::string> seen;
  const std::string parent = work_path.parent_path().string();
  if (seen.insert(parent).second) all_l.push_back(parent);
  for (const auto& p : l_paths) {
    if (seen.insert(p).second) all_l.push_back(p);
  }

  // Build the prefix portion of the argv common to every analysis:
  //   [nvc, --std=..., -L p1, -L p2, ..., --work=..., -a, (--relaxed)]
  // The bootstrap flag is inserted only for the first source.
  std::vector<std::string> base_argv;
  base_argv.push_back(nvc_path);
  base_argv.push_back("--std=" + std_arg);
  for (const auto& p : all_l) {
    base_argv.push_back("-L");
    base_argv.push_back(p);
  }
  base_argv.push_back("--work=" + work);
  base_argv.push_back("-a");
  if (relaxed) base_argv.push_back("--relaxed");

  for (size_t i = 0; i < srcs.size(); ++i) {
    std::vector<std::string> argv_run = base_argv;
    if (bootstrap_first && i == 0) {
      // `--bootstrap` follows `-a` in the upstream Makefile invocation.
      argv_run.push_back("--bootstrap");
    }
    argv_run.push_back(srcs[i]);

    const int rc = run_subprocess(argv_run);
    if (rc != 0) {
      std::cerr << "vhdl_compile: nvc failed (exit " << rc
                << ") analysing " << srcs[i] << "\n";
      return rc;
    }
  }
  return 0;
}
