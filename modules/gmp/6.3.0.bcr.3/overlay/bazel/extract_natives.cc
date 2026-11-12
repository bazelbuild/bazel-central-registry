/**
 * @file extract_natives.cc
 * @brief Extracts HAVE_NATIVE_mpn_* defines from GMP assembly files.
 *
 * Mirrors configure.ac lines 3564-3571: parses @c PROLOGUE() and
 * @c MULFUNC_PROLOGUE() declarations from @c .asm files and emits
 * autoconf-compatible result JSON files for @c CcAutoconfInfo.
 *
 * @par Usage
 * @code
 * extract_natives <manifest_file> [asm_file ...]
 * @endcode
 *
 * The manifest file contains one line per define:
 * @c HAVE_NATIVE_mpn_add_n\t/path/to/output.result.json
 *
 * Each output file receives a JSON result: @c {"success":true,"value":"1"}
 * if the function was found, @c {"success":false,"value":null} otherwise.
 */

#include <cstdio>
#include <fstream>
#include <regex>
#include <set>
#include <sstream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc < 2) {
        fprintf(stderr,
                "Usage: %s <manifest_file> [asm_file ...]\n",
                argv[0]);
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
                        natives.insert("HAVE_NATIVE_" + name);
                    }
                }
            } else if (std::regex_search(line, m, prologue_re)) {
                std::string name = m[1].str();
                if (name.rfind("mpn_", 0) == 0) {
                    natives.insert("HAVE_NATIVE_" + name);
                }
            }
        }
    }

    static const char* RESULT_FOUND =
        "{\n    \"success\": true,\n    \"value\": \"1\"\n}\n";
    static const char* RESULT_NOT_FOUND =
        "{\n    \"success\": false,\n    \"value\": null\n}\n";

    std::ifstream manifest(argv[1]);
    if (!manifest) {
        fprintf(stderr, "extract_natives: cannot open manifest %s\n",
                argv[1]);
        return 1;
    }

    std::string line;
    while (std::getline(manifest, line)) {
        auto tab = line.find('\t');
        if (tab == std::string::npos) continue;
        std::string define_name = line.substr(0, tab);
        std::string output_path = line.substr(tab + 1);

        std::ofstream out(output_path);
        if (!out) {
            fprintf(stderr, "extract_natives: cannot open %s for writing\n",
                    output_path.c_str());
            return 1;
        }

        if (natives.count(define_name)) {
            out << RESULT_FOUND;
        } else {
            out << RESULT_NOT_FOUND;
        }
    }

    return 0;
}
