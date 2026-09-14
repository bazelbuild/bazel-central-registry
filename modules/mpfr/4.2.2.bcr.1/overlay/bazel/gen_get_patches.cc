/// @file gen_get_patches.cc
/// @brief Generates get_patches.c from the MPFR PATCHES file.
///
/// Replaces upstream tools/get_patches.sh for Bazel builds.  Reads patch
/// names (one per line) from the PATCHES file and emits a C source file
/// that defines @c mpfr_get_patches(), which returns the patch list as a
/// single newline-separated string.
///
/// @par Usage
/// @code
/// gen_get_patches <output_file> <patches_file>
/// @endcode

#include <fstream>
#include <iostream>
#include <string>
#include <vector>

/// @brief Read non-empty, non-comment lines from @p path.
static std::vector<std::string> read_patches(const char* path) {
    std::vector<std::string> patches;
    std::ifstream in(path);
    if (!in) return patches;
    std::string line;
    while (std::getline(in, line)) {
        if (!line.empty() && line[0] != '#') {
            patches.push_back(line);
        }
    }
    return patches;
}

/// @brief Write a C string literal to @p out, escaping special characters.
static void write_escaped(std::ostream& out, const std::string& s) {
    for (char c : s) {
        if (c == '"' || c == '\\') out.put('\\');
        out.put(c);
    }
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0]
                  << " <output_file> <patches_file>\n";
        return 1;
    }

    auto patches = read_patches(argv[2]);

    std::ofstream out(argv[1], std::ios::binary);
    if (!out) {
        std::cerr << "Cannot open " << argv[1] << " for writing\n";
        return 1;
    }

    out << "#include \"mpfr-impl.h\"\n"
        << "\n"
        << "const char *\n"
        << "mpfr_get_patches (void)\n"
        << "{\n"
        << "  return \"";
    for (size_t i = 0; i < patches.size(); ++i) {
        if (i > 0) out << "\\n";
        write_escaped(out, patches[i]);
    }
    out << "\";\n"
        << "}\n";

    return 0;
}
