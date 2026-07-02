/**
 * @file gen_config_m4.cc
 * @brief Generates config.m4 for GMP assembly preprocessing.
 *
 * Mirrors the relevant parts of configure.ac that produce config.m4:
 * assembly syntax constants (determined by OS/object format), architecture
 * include directives, and threshold values (parsed from gmp-mparam.h).
 *
 * @par Usage
 * @code
 * gen_config_m4 <output> <arch> <os> <mparam_h>
 * @endcode
 *
 * @param arch     CPU architecture: x86_64, aarch64, arm, powerpc64, etc.
 * @param os       Target OS: linux, macos, windows.
 * @param mparam_h Path to the selected gmp-mparam.h.
 */

#include <cstdio>
#include <cstring>
#include <fstream>
#include <regex>
#include <string>
#include <vector>

/**
 * @brief Assembly syntax constants for a given object format.
 */
struct AsmSyntax {
    const char* text;             ///< Text section directive.
    const char* data;             ///< Data section directive.
    const char* label_suffix;     ///< Suffix after labels (typically ":").
    const char* globl;            ///< Global symbol directive.
    const char* globl_attr;       ///< Additional global symbol attributes.
    const char* gsym_prefix;      ///< Global symbol prefix ("_" on Mach-O).
    const char* rodata;           ///< Read-only data section (unused; computed per-arch).
    const char* type_fmt;         ///< ELF .type directive format (empty on Mach-O/COFF).
    const char* size_fmt;         ///< ELF .size directive format (empty on Mach-O/COFF).
    const char* lsym_prefix;      ///< Local symbol prefix (".L" on ELF, "L" on Mach-O).
    const char* w32;              ///< 32-bit word directive.
    bool align_logarithmic;       ///< Whether ALIGN uses logarithmic values.
    bool align_fill_0x90;         ///< Whether to fill alignment with 0x90 (NOP).
    bool have_coff_type;          ///< Whether COFF .def/.endef type directives are used.
};

/** @name Object format syntax tables */
/** @{ */
static const AsmSyntax ELF_SYNTAX = {
    ".text", ".data", ":", ".globl", "", "", nullptr,
    ".type\t$1,@$2", ".size\t$1,$2", ".L", ".long",
    false, false, false,
};

static const AsmSyntax MACHO_SYNTAX = {
    ".text", ".data", ":", ".globl", "", "_", nullptr,
    "", "", "L", ".long",
    false, false, false,
};

static const AsmSyntax COFF_SYNTAX = {
    ".text", ".data", ":", ".globl", "", "", nullptr,
    "", "", "L", ".long",
    false, false, true,
};
/** @} */

/**
 * @brief Returns the RODATA section directive for the given arch and OS.
 */
static std::string rodata_for(const char* arch, const char* os) {
    if (strcmp(os, "macos") == 0)
        return "\t.section\t__TEXT,__const";
    if (strcmp(os, "windows") == 0)
        return "\t.section\t.rdata,\"dr\"";
    if (strcmp(arch, "x86_64") == 0 || strcmp(arch, "x86") == 0)
        return "\t.section\t.rodata,\"a\",@progbits";
    return "\t.section\t.rodata";
}

/**
 * @brief Returns true if @p arch is an ARM variant.
 */
static bool is_arm(const char* arch) {
    return strcmp(arch, "aarch64") == 0 || strcmp(arch, "arm64") == 0 ||
           strcmp(arch, "arm") == 0;
}

/**
 * @brief Returns true if @p arch is an x86 variant.
 */
static bool is_x86(const char* arch) {
    return strcmp(arch, "x86_64") == 0 || strcmp(arch, "x86") == 0;
}

/**
 * @brief Architecture-specific config.m4 settings.
 */
struct ArchConfig {
    std::vector<std::string> include_mpn; ///< Arch/OS-specific M4 files to include.
    std::string host_cpu;  ///< Host CPU name for define_not_for_expansion (e.g. "aarch64").
    bool have_abi_64;      ///< Whether the ABI is 64-bit.
    bool is_linux;         ///< Whether the target OS is Linux.
};

/**
 * @brief Builds architecture-specific configuration from arch, OS, and limb size.
 */
static ArchConfig arch_config(const char* arch, const char* os, int limb_bits) {
    ArchConfig cfg = {};
    cfg.is_linux = strcmp(os, "linux") == 0;
    cfg.have_abi_64 = limb_bits == 64;
    bool is_darwin = strcmp(os, "macos") == 0;
    bool is_windows = strcmp(os, "windows") == 0;

    if (strcmp(arch, "x86_64") == 0) {
        cfg.include_mpn.push_back("x86_64/x86_64-defs.m4");
        if (is_darwin)
            cfg.include_mpn.push_back("x86_64/darwin.m4");
        else if (is_windows)
            cfg.include_mpn.push_back("x86_64/dos64.m4");
    } else if (strcmp(arch, "x86") == 0) {
        cfg.include_mpn.push_back("x86/x86-defs.m4");
        if (is_darwin)
            cfg.include_mpn.push_back("x86/darwin.m4");
    } else if (strcmp(arch, "aarch64") == 0) {
        if (is_darwin)
            cfg.include_mpn.push_back("arm64/darwin.m4");
        else
            cfg.include_mpn.push_back("arm64/arm64-defs.m4");
        cfg.host_cpu = "aarch64";
    } else if (strcmp(arch, "arm") == 0) {
        cfg.include_mpn.push_back("arm/arm-defs.m4");
    } else if (strcmp(arch, "powerpc64") == 0) {
        cfg.include_mpn.push_back("powerpc32/powerpc-defs.m4");
        if (is_darwin)
            cfg.include_mpn.push_back("powerpc64/darwin.m4");
        else
            cfg.include_mpn.push_back("powerpc64/elf.m4");
    } else if (strcmp(arch, "powerpc32") == 0) {
        cfg.include_mpn.push_back("powerpc32/powerpc-defs.m4");
        if (is_darwin)
            cfg.include_mpn.push_back("powerpc32/darwin.m4");
        else
            cfg.include_mpn.push_back("powerpc32/elf.m4");
    } else if (strcmp(arch, "s390_64") == 0) {
        cfg.include_mpn.push_back("s390_64/s390_64-defs.m4");
    } else if (strcmp(arch, "mips64") == 0 || strcmp(arch, "mips32") == 0) {
        cfg.include_mpn.push_back("mips32/mips-defs.m4");
    }
    return cfg;
}

/**
 * @brief Extracts a numeric @c \#define value from gmp-mparam.h content.
 *
 * @param content The full text of gmp-mparam.h.
 * @param name    The macro name to search for.
 * @return The value as a string, or empty if not found.
 */
static std::string parse_mparam_value(const std::string& content,
                                      const char* name) {
    std::regex re(std::string("#define\\s+") + name + "\\s+(\\d+)");
    std::smatch m;
    if (std::regex_search(content, m, re))
        return m[1].str();
    return "";
}

int main(int argc, char* argv[]) {
    if (argc < 5) {
        fprintf(stderr, "Usage: %s <output> <arch> <os> <mparam_h>\n",
                argv[0]);
        return 1;
    }

    const char* output_path = argv[1];
    const char* arch = argv[2];
    const char* os = argv[3];
    const char* mparam_path = argv[4];

    std::string mparam_content;
    {
        std::ifstream in(mparam_path);
        if (!in) {
            fprintf(stderr, "gen_config_m4: cannot open %s\n", mparam_path);
            return 1;
        }
        mparam_content.assign(std::istreambuf_iterator<char>(in), {});
    }

    const AsmSyntax* syntax = &ELF_SYNTAX;
    if (strcmp(os, "macos") == 0)
        syntax = &MACHO_SYNTAX;
    else if (strcmp(os, "windows") == 0)
        syntax = &COFF_SYNTAX;

    int limb_bits = 64;
    std::string mparam_limb = parse_mparam_value(mparam_content, "GMP_LIMB_BITS");
    if (!mparam_limb.empty())
        limb_bits = std::stoi(mparam_limb);

    ArchConfig cfg = arch_config(arch, os, limb_bits);
    std::string rodata = rodata_for(arch, os);

    std::ofstream out(output_path);
    if (!out) {
        fprintf(stderr, "gen_config_m4: cannot open %s for writing\n",
                output_path);
        return 1;
    }

    out << "dnl config.m4.  Generated by gen_config_m4.\n";
    out << "changequote(<,>)\n";
    out << "ifdef(<__CONFIG_M4_INCLUDED__>,,<\n";
    out << "define(<CONFIG_TOP_SRCDIR>,<`.'>)\n";
    out << "define(<WANT_ASSERT>,0)\n";
    out << "define(<WANT_PROFILING>,<`no'>)\n";
    out << "define(<M4WRAP_SPURIOUS>,<no>)\n";
    out << "define(<TEXT>, <" << syntax->text << ">)\n";
    out << "define(<DATA>, <" << syntax->data << ">)\n";
    out << "define(<LABEL_SUFFIX>, <" << syntax->label_suffix << ">)\n";
    out << "define(<GLOBL>, <" << syntax->globl << ">)\n";
    out << "define(<GLOBL_ATTR>, <" << syntax->globl_attr << ">)\n";
    out << "define(<GSYM_PREFIX>, <" << syntax->gsym_prefix << ">)\n";
    out << "define(<RODATA>, <" << rodata << ">)\n";
    out << "define(<TYPE>, <" << syntax->type_fmt << ">)\n";
    out << "define(<SIZE>, <" << syntax->size_fmt << ">)\n";
    out << "define(<LSYM_PREFIX>, <" << syntax->lsym_prefix << ">)\n";
    out << "define(<W32>, <" << syntax->w32 << ">)\n";

    bool align_log = is_arm(arch) ? true : syntax->align_logarithmic;
    out << "define(<ALIGN_LOGARITHMIC>,<" << (align_log ? "yes" : "no")
        << ">)\n";

    if (is_x86(arch)) {
        out << "define(<ALIGN_FILL_0x90>,<yes>)\n";
        out << "define(<HAVE_COFF_TYPE>,<"
            << (syntax->have_coff_type ? "yes" : "no") << ">)\n";
    }

    if (cfg.is_linux)
        out << "define(<LINUX>,1)\n";

    const char* thresholds[] = {"SQR_TOOM2_THRESHOLD",
                                "BMOD_1_TO_MOD_1_THRESHOLD", "SHLD_SLOW",
                                "SHRD_SLOW"};
    for (const char* name : thresholds) {
        std::string val = parse_mparam_value(mparam_content, name);
        if (!val.empty())
            out << "define(<" << name << ">,<" << val << ">)\n";
    }

    out << "define(<SIZEOF_UNSIGNED>,<4>)\n";
    out << "define(<GMP_LIMB_BITS>," << limb_bits << ")\n";
    out << "define(<GMP_NAIL_BITS>,0)\n";
    out << "define(<GMP_NUMB_BITS>,eval(GMP_LIMB_BITS-GMP_NAIL_BITS))\n";
    out << ">)\n";

    out << "changequote(`,\')\n";
    out << "ifdef(`__CONFIG_M4_INCLUDED__\',,`\n";
    out << "include(CONFIG_TOP_SRCDIR`/mpn/asm-defs.m4\')\n";

    for (const auto& inc : cfg.include_mpn)
        out << "include_mpn(`" << inc << "\')\n";
    if (!cfg.host_cpu.empty())
        out << "define_not_for_expansion(`HAVE_HOST_CPU_" << cfg.host_cpu
            << "\')\n";
    if (cfg.have_abi_64)
        out << "define_not_for_expansion(`HAVE_ABI_64\')\n";

    out << "define_not_for_expansion(`HAVE_LIMB_LITTLE_ENDIAN\')\n";
    out << "define_not_for_expansion(`HAVE_DOUBLE_IEEE_LITTLE_ENDIAN\')\n";

    out << "\')\n";
    out << "define(`__CONFIG_M4_INCLUDED__\')\n";

    return 0;
}
