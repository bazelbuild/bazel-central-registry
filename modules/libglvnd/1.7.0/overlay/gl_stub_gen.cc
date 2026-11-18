// Generates the C source for a link-time-only libglvnd stub library from one
// of upstream's export lists (src/<lib>/<lib>.symbols), which libglvnd's own
// "symbols check" tests use as the authoritative ABI of each library.
//
// Usage: gl_stub_gen <input.symbols> <output.c>

#include <cctype>
#include <fstream>
#include <iostream>
#include <set>
#include <string>

namespace {

bool is_identifier(const std::string& s) {
    if (s.empty() || std::isdigit(static_cast<unsigned char>(s[0]))) {
        return false;
    }
    for (char c : s) {
        if (!std::isalnum(static_cast<unsigned char>(c)) && c != '_') {
            return false;
        }
    }
    return true;
}

std::string trim(const std::string& s) {
    const char* ws = " \t\r\n";
    const size_t b = s.find_first_not_of(ws);
    if (b == std::string::npos) {
        return "";
    }
    return s.substr(b, s.find_last_not_of(ws) - b + 1);
}

}  // namespace

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "Usage: gl_stub_gen <input.symbols> <output.c>\n";
        return 1;
    }
    std::ifstream in(argv[1]);
    if (!in) {
        std::cerr << "gl_stub_gen: cannot read " << argv[1] << "\n";
        return 1;
    }
    std::set<std::string> syms;
    std::string line;
    int lineno = 0;
    while (std::getline(in, line)) {
        ++lineno;
        line = trim(line);
        if (line.empty() || line[0] == '#') {
            continue;
        }
        if (!is_identifier(line)) {
            std::cerr << argv[1] << ":" << lineno << ": not a symbol name: " << line << "\n";
            return 1;
        }
        syms.insert(line);
    }
    if (syms.empty()) {
        std::cerr << "gl_stub_gen: no symbols in " << argv[1] << "\n";
        return 1;
    }

    std::ofstream out(argv[2], std::ios::binary);
    if (!out) {
        std::cerr << "gl_stub_gen: cannot write " << argv[2] << "\n";
        return 1;
    }
    out << "/* Generated from " << argv[1] << ". Link-time stub only: never load at runtime. */\n";
    for (const auto& sym : syms) {
        out << "__attribute__((visibility(\"default\"))) void " << sym << "(void) {}\n";
    }
    return out ? 0 : 1;
}
