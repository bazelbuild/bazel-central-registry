// Hermetic ELF checks for the libglvnd stubs (no nm/readelf needed):
//
//   elf_check exports <lib.so> <upstream.symbols>
//       The library's defined dynamic symbols must equal the upstream list.
//       This is the check upstream runs as "symbols check" (bin/symbols-check.py).
//
//   elf_check needed <binary> [expected SONAME...]
//       The binary's DT_NEEDED entries for libglvnd libraries (libGL*, libEGL*,
//       libOpenGL*) must be exactly the expected set.

#include <elf.h>

#include <cstring>
#include <fstream>
#include <iostream>
#include <iterator>
#include <set>
#include <string>
#include <vector>

namespace {

struct ElfInfo {
    std::set<std::string> exports;
    std::set<std::string> needed;
};

const char* str_at(const std::vector<char>& d, size_t table_off, size_t table_size, size_t idx) {
    if (idx >= table_size || table_off + table_size > d.size()) {
        return "";
    }
    const char* s = d.data() + table_off + idx;
    return memchr(s, '\0', table_size - idx) ? s : "";
}

template <class Ehdr, class Shdr, class Sym, class Dyn>
bool parse(const std::vector<char>& d, ElfInfo* info) {
    if (d.size() < sizeof(Ehdr)) {
        return false;
    }
    const auto* eh = reinterpret_cast<const Ehdr*>(d.data());
    if (eh->e_shoff == 0 || eh->e_shentsize != sizeof(Shdr) ||
        eh->e_shoff + static_cast<size_t>(eh->e_shnum) * sizeof(Shdr) > d.size()) {
        return false;
    }
    const auto* sh = reinterpret_cast<const Shdr*>(d.data() + eh->e_shoff);
    for (size_t i = 0; i < eh->e_shnum; ++i) {
        if (sh[i].sh_type != SHT_DYNSYM && sh[i].sh_type != SHT_DYNAMIC) {
            continue;
        }
        if (sh[i].sh_link >= eh->e_shnum || sh[i].sh_offset + sh[i].sh_size > d.size()) {
            return false;
        }
        const Shdr& strtab = sh[sh[i].sh_link];
        if (sh[i].sh_type == SHT_DYNSYM) {
            const auto* syms = reinterpret_cast<const Sym*>(d.data() + sh[i].sh_offset);
            for (size_t k = 0; k < sh[i].sh_size / sizeof(Sym); ++k) {
                const unsigned bind = ELF64_ST_BIND(syms[k].st_info);
                if (syms[k].st_shndx == SHN_UNDEF || (bind != STB_GLOBAL && bind != STB_WEAK) ||
                    ELF64_ST_VISIBILITY(syms[k].st_other) != STV_DEFAULT) {
                    continue;
                }
                const std::string name = str_at(d, strtab.sh_offset, strtab.sh_size, syms[k].st_name);
                if (!name.empty()) {
                    info->exports.insert(name);
                }
            }
        } else {
            const auto* dyn = reinterpret_cast<const Dyn*>(d.data() + sh[i].sh_offset);
            for (size_t k = 0; k < sh[i].sh_size / sizeof(Dyn) && dyn[k].d_tag != DT_NULL; ++k) {
                if (dyn[k].d_tag == DT_NEEDED) {
                    info->needed.insert(str_at(d, strtab.sh_offset, strtab.sh_size, dyn[k].d_un.d_val));
                }
            }
        }
    }
    return true;
}

bool load(const std::string& path, ElfInfo* info) {
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        std::cerr << "cannot open " << path << "\n";
        return false;
    }
    std::vector<char> d((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    if (d.size() < EI_NIDENT || memcmp(d.data(), ELFMAG, SELFMAG) != 0) {
        std::cerr << path << ": not an ELF file\n";
        return false;
    }
    const bool ok = d[EI_CLASS] == ELFCLASS64
                        ? parse<Elf64_Ehdr, Elf64_Shdr, Elf64_Sym, Elf64_Dyn>(d, info)
                        : parse<Elf32_Ehdr, Elf32_Shdr, Elf32_Sym, Elf32_Dyn>(d, info);
    if (!ok) {
        std::cerr << path << ": malformed ELF\n";
    }
    return ok;
}

// Prints a - b, up to a limit; returns the number of elements.
size_t report(const char* label, const std::set<std::string>& a, const std::set<std::string>& b) {
    size_t n = 0;
    for (const auto& s : a) {
        if (b.count(s)) {
            continue;
        }
        if (n++ < 25) {
            std::cerr << "  " << label << ": " << s << "\n";
        }
    }
    if (n > 25) {
        std::cerr << "  ... and " << (n - 25) << " more " << label << "\n";
    }
    return n;
}

int check_exports(const std::string& lib, const std::string& symbols_path) {
    ElfInfo info;
    if (!load(lib, &info)) {
        return 1;
    }
    // Symbols some linkers export from every shared library.
    for (const char* s : {"_init", "_fini", "_edata", "_end", "__bss_start"}) {
        info.exports.erase(s);
    }
    std::ifstream in(symbols_path);
    if (!in) {
        std::cerr << "cannot open " << symbols_path << "\n";
        return 1;
    }
    std::set<std::string> expected;
    for (std::string line; std::getline(in, line);) {
        line.erase(line.find_last_not_of(" \t\r") + 1);
        if (!line.empty() && line[0] != '#') {
            expected.insert(line);
        }
    }
    const size_t missing = report("missing", expected, info.exports);
    const size_t extra = report("unexpected", info.exports, expected);
    std::cout << lib << ": " << info.exports.size() << " exports, " << expected.size()
              << " expected, " << missing << " missing, " << extra << " unexpected\n";
    return (missing || extra) ? 1 : 0;
}

bool is_glvnd_lib(const std::string& s) {
    return s.rfind("libGL", 0) == 0 || s.rfind("libEGL", 0) == 0 || s.rfind("libOpenGL", 0) == 0;
}

int check_needed(const std::string& bin, const std::set<std::string>& expected) {
    ElfInfo info;
    if (!load(bin, &info)) {
        return 1;
    }
    std::set<std::string> actual;
    for (const auto& s : info.needed) {
        if (is_glvnd_lib(s)) {
            actual.insert(s);
        }
    }
    const size_t missing = report("missing DT_NEEDED", expected, actual);
    const size_t extra = report("unexpected DT_NEEDED", actual, expected);
    std::cout << bin << ": libglvnd DT_NEEDED = {";
    for (const auto& s : actual) {
        std::cout << " " << s;
    }
    std::cout << " }\n";
    return (missing || extra) ? 1 : 0;
}

}  // namespace

int main(int argc, char** argv) {
    const std::string mode = argc > 1 ? argv[1] : "";
    if (mode == "exports" && argc == 4) {
        return check_exports(argv[2], argv[3]);
    }
    if (mode == "needed" && argc >= 3) {
        return check_needed(argv[2], std::set<std::string>(argv + 3, argv + argc));
    }
    std::cerr << "usage: elf_check exports <lib.so> <file.symbols>\n"
                 "       elf_check needed <binary> [SONAME...]\n";
    return 2;
}
