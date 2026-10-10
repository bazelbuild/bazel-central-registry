/// @file css_to_header.cc
/// @brief Convert a CSS file into a C header containing a single string
///        literal.
///
/// Replaces the upstream `sed` pipeline in `src/cov/Makemodule.am`
/// that generates `src/cov/cov-style.h` from `src/cov/cov-style.css`.
/// Each line of CSS becomes a `"...\n"` C string literal joined into
/// a static `char[]` constant.
///
/// Usage: `css_to_header --in INPUT --out OUTPUT --varname NAME`
///
/// Pure I/O — no subprocesses, no platform-specific APIs. Compiles
/// unmodified on Linux, macOS, and Windows.

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>

namespace {

/// Print a diagnostic and exit with status 2 (matching getopt's
/// convention for argument errors).
[[noreturn]] void die(const std::string& msg) {
  std::cerr << "css_to_header: " << msg << "\n";
  std::exit(2);
}

/// Escape a single CSS line for embedding inside a C string literal:
/// backslashes and double-quotes get a leading backslash. All other
/// bytes — including non-ASCII UTF-8 — are passed through verbatim.
std::string escape_for_c_string(const std::string& line) {
  std::string out;
  out.reserve(line.size());
  for (char c : line) {
    if (c == '\\' || c == '"') {
      out.push_back('\\');
    }
    out.push_back(c);
  }
  return out;
}

}  // namespace

int main(int argc, char** argv) {
  std::string in_path;
  std::string out_path;
  std::string var_name;

  for (int i = 1; i < argc; ++i) {
    const std::string flag = argv[i];
    if (flag == "--in" && i + 1 < argc) {
      in_path = argv[++i];
    } else if (flag == "--out" && i + 1 < argc) {
      out_path = argv[++i];
    } else if (flag == "--varname" && i + 1 < argc) {
      var_name = argv[++i];
    } else {
      die("unknown argument: " + flag);
    }
  }

  if (in_path.empty()) die("--in is required");
  if (out_path.empty()) die("--out is required");
  if (var_name.empty()) die("--varname is required");

  std::ifstream in(in_path);
  if (!in) die("could not open input: " + in_path);

  std::ofstream out(out_path);
  if (!out) die("could not open output: " + out_path);

  out << "static const char " << var_name << "[] =\n";

  std::string line;
  while (std::getline(in, line)) {
    out << "\"" << escape_for_c_string(line) << "\\n\"\n";
  }
  out << ";\n";

  if (!out) die("write failed for: " + out_path);
  return 0;
}
