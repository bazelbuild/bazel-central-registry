/**
 * @file extract_natives.cc
 * @brief Extracts HAVE_NATIVE_mpn_* defines from GMP assembly files.
 *
 * Mirrors configure.ac lines 3564-3571: parses @c PROLOGUE() and
 * @c MULFUNC_PROLOGUE() declarations from @c .asm files and emits
 * @c \#define @c HAVE_NATIVE_<name> @c 1 for each declared function.
 *
 * @par Usage
 * @code
 * extract_natives <output_file> [asm_file ...]
 * @endcode
 */

#include <cstdio>
#include <fstream>
#include <regex>
#include <set>
#include <sstream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <output> [asm_file ...]\n", argv[0]);
        return 1;
    }

    std::set<std::string> natives;
    std::regex mulfunc_re(R"(^\s*MULFUNC_PROLOGUE\((.+)\))");
    std::regex prologue_re(R"(^\s*PROLOGUE\(([^,)]+))");

    for (int i = 2; i < argc; i++) {
        std::ifstream in(argv[i]);
        if (!in) {
            fprintf(stderr, "extract_natives: cannot open %s\n", argv[i]);
            return 1;
        }

        std::string line;
        while (std::getline(in, line)) {
            std::smatch m;
            if (std::regex_search(line, m, mulfunc_re)) {
                std::istringstream names(m[1].str());
                std::string name;
                while (names >> name) {
                    if (name.rfind("mpn_", 0) == 0) {
                        natives.insert(name);
                    }
                }
            } else if (std::regex_search(line, m, prologue_re)) {
                std::string name = m[1].str();
                if (name.rfind("mpn_", 0) == 0) {
                    natives.insert(name);
                }
            }
        }
    }

    std::ofstream out(argv[1]);
    if (!out) {
        fprintf(stderr, "extract_natives: cannot open %s for writing\n",
                argv[1]);
        return 1;
    }

    out << "/* Generated from .asm PROLOGUE/MULFUNC_PROLOGUE declarations. "
           "*/\n";
    for (const auto& name : natives) {
        out << "#define HAVE_NATIVE_" << name << " 1\n";
    }

    return 0;
}
