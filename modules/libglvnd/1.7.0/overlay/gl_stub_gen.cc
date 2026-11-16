// Generates link-time-only libglvnd stub C sources (libGL.so.1, libGLX.so.0,
// libOpenGL.so.0, libEGL.so.1) from Khronos registry headers.

#include <cctype>
#include <fstream>
#include <iostream>
#include <set>
#include <string>

namespace {

bool is_ident_char(char c) {
    return std::isalnum(static_cast<unsigned char>(c)) || c == '_';
}

void scan_file(
    const std::string& path,
    const std::string& prefix,
    std::set<std::string>& out_syms) {
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        return;
    }
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    const size_t n = text.size();
    const size_t plen = prefix.size();
    for (size_t i = 0; i + plen < n; ++i) {
        if (i > 0 && is_ident_char(text[i - 1])) {
            continue;
        }
        if (text.compare(i, plen, prefix) != 0) {
            continue;
        }
        char next_c = text[i + plen];
        if (!std::isupper(static_cast<unsigned char>(next_c))) {
            continue;
        }
        size_t j = i + plen + 1;
        while (j < n && is_ident_char(text[j])) {
            ++j;
        }
        size_t k = j;
        while (k < n && std::isspace(static_cast<unsigned char>(text[k]))) {
            ++k;
        }
        if (k < n && text[k] == '(') {
            out_syms.insert(text.substr(i, j - i));
        }
        i = j;
    }
}

bool write_stub(const std::string& out_path, const std::set<std::string>& syms) {
    std::ofstream out(out_path, std::ios::binary);
    if (!out) {
        std::cerr << "Failed to open output: " << out_path << "\n";
        return false;
    }
    out << "/* Auto-generated Khronos libglvnd link-time stub */\n";
    for (const auto& sym : syms) {
        out << "__attribute__((visibility(\"default\"))) void " << sym << "(void) {}\n";
    }
    return static_cast<bool>(out);
}

}  // namespace

int main(int argc, char** argv) {
    if (argc < 5) {
        std::cerr << "Usage: gl_stub_gen <gl.c> <glx.c> <opengl.c> <egl.c> [headers...]\n";
        return 1;
    }
    std::string out_gl = argv[1];
    std::string out_glx = argv[2];
    std::string out_opengl = argv[3];
    std::string out_egl = argv[4];

    std::set<std::string> gl_syms;
    std::set<std::string> glx_syms;
    std::set<std::string> egl_syms;

    for (int i = 5; i < argc; ++i) {
        std::string path = argv[i];
        if (path.find("egl") != std::string::npos || path.find("EGL") != std::string::npos) {
            scan_file(path, "egl", egl_syms);
        } else if (path.find("glx") != std::string::npos) {
            scan_file(path, "glX", glx_syms);
        } else {
            scan_file(path, "gl", gl_syms);
        }
    }

    std::set<std::string> gl_and_glx = gl_syms;
    gl_and_glx.insert(glx_syms.begin(), glx_syms.end());

    if (!write_stub(out_gl, gl_and_glx) ||
        !write_stub(out_glx, gl_and_glx) ||
        !write_stub(out_opengl, gl_syms) ||
        !write_stub(out_egl, egl_syms)) {
        return 1;
    }
    return 0;
}
