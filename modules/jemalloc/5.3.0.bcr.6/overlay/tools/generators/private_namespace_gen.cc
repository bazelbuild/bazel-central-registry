// Generates private_namespace.h from an `nm -a` (or `dumpbin /SYMBOLS`) listing, as upstream's private_symbols.awk
// and private_namespace.sh do. It adds no shell or awk of its own: the lister is run directly, so it and any
// interpreter a wrapper needs remain the dependencies of whatever supplies it, the C++ toolchain or
// //settings/flags:nm.
//
//   private_namespace_gen list LISTER LISTING STDERR ARGUMENT...
//   private_namespace_gen header HEADER LISTING STDERR SYM_PREFIX LISTING_SOURCE UNFOUND_REASON [--prefix=PREFIX]
//       [--public=SYMBOL]... [--public-file=PATH]... [--wrap=SYMBOL]... [--wrap-file=PATH]... [--export-syms=PATH]
//
// list mode runs LISTER with the ARGUMENTs, its options and then the archives, with stdout to LISTING and stderr to
// STDERR: `nm -a ARCHIVE...`, or `link /DUMP /SYMBOLS ARCHIVE...` (dumpbin) with an MSVC toolchain.
//
// Each public symbol, given directly or as a line of a --public-file, is exported as PREFIX followed by the symbol;
// each wrapped symbol as is. --export-syms writes configure.ac's export_syms: the exported public symbols, then the
// wrapped ones, one per line.

#include <fstream>
#include <iostream>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "private_namespace_listing.h"
#include "process.h"

namespace {

using private_namespace::dumpbin_external_symbol;
using private_namespace::is_defined_symbol_type;
using private_namespace::is_identifier;
using private_namespace::read_lines;
using private_namespace::read_nm_diagnostics;
using private_namespace::split_fields;
using private_namespace::starts_with;

const std::string kPrefixFlag = "--prefix=";
const std::string kPublicFlag = "--public=";
const std::string kPublicFileFlag = "--public-file=";
const std::string kWrapFlag = "--wrap=";
const std::string kWrapFileFlag = "--wrap-file=";
const std::string kExportSymsFlag = "--export-syms=";

// Appends each nonempty line of `path` to *symbols.
bool read_symbols(const std::string& path, std::vector<std::string>* symbols) {
    std::vector<std::string> lines;
    if (!read_lines(path, &lines)) return false;
    for (const std::string& line : lines) {
        if (!line.empty()) symbols->push_back(line);
    }
    return true;
}

bool write_export_syms(const std::string& path, const std::vector<std::string>& public_symbols,
                       const std::vector<std::string>& wrap_symbols) {
    std::ofstream export_syms(path, std::ios::binary);
    for (const std::string& symbol : public_symbols) export_syms << symbol << "\n";
    for (const std::string& symbol : wrap_symbols) export_syms << symbol << "\n";
    export_syms.close();
    if (!export_syms) {
        std::cerr << "private_namespace: error writing " << path << "\n";
        return false;
    }
    return true;
}

// Prints the lister's stderr, for a lister that failed.
void print_lister_stderr(const std::string& stderr_path) {
    std::ifstream lister_stderr(stderr_path, std::ios::binary);
    std::cerr << lister_stderr.rdbuf();
}

int run_lister(const std::string& lister, const std::string& listing_path, const std::string& stderr_path,
               const std::vector<std::string>& arguments) {
    int exit_code;
    std::string error;
    if (!process::run(lister, arguments, &listing_path, stderr_path, &exit_code, &error)) {
        std::cerr << "private_namespace: " << error << "\n";
        return 1;
    }
    if (exit_code == 0) return 0;
    print_lister_stderr(stderr_path);
    return exit_code;
}

// An nm without the GCC LTO plugin reads slim-LTO objects silently as just __gnu_lto_slim. Any one public symbol
// suffices: the list also names symbols that only some configurations define (smallocx_*).
int write_header(const std::string& header_path, const std::string& listing_path, const std::string& stderr_path,
                 const std::string& sym_prefix, const std::string& listing_source, const std::string& unfound_reason,
                 const std::vector<std::string>& public_symbols, const std::vector<std::string>& wrap_symbols) {
    std::set<std::string> exported_symbols, public_api_symbols;
    for (const std::string& symbol : public_symbols) {
        exported_symbols.insert(sym_prefix + symbol);
        public_api_symbols.insert(sym_prefix + symbol);
    }
    for (const std::string& symbol : wrap_symbols) exported_symbols.insert(sym_prefix + symbol);
    std::string diagnostics;
    if (!read_nm_diagnostics(stderr_path, &diagnostics)) return 1;

    std::vector<std::string> listing_lines;
    if (!read_lines(listing_path, &listing_lines)) return 1;
    std::ostringstream header_text;
    auto define_private = [&header_text](const std::string& symbol) {
        if (!symbol.empty()) header_text << "#define " << symbol << " JEMALLOC_N(" << symbol << ")\n";
    };
    bool has_slim_lto = false, found_public_symbol = false;
    for (const std::string& line : listing_lines) {
        std::vector<std::string> fields = split_fields(line);
        std::size_t field_count = fields.size();
        // nm -a: "ADDRESS TYPE NAME"
        if (field_count == 3) {
            const std::string& symbol_type = fields[1];
            const std::string& name = fields[2];
            if (name == sym_prefix + "__gnu_lto_slim") has_slim_lto = true;
            if (is_defined_symbol_type(symbol_type) && public_api_symbols.count(name)) found_public_symbol = true;
            if (is_defined_symbol_type(symbol_type) && !exported_symbols.count(name) && is_identifier(name)) {
                define_private(name.size() > sym_prefix.size() ? name.substr(sym_prefix.size()) : "");
            }
        }
        // dumpbin /SYMBOLS. Unlike private_symbols.awk, only identifiers are namespaced, as for nm: MSVC also gives
        // external linkage to its constant pool entries, such as __real@3ff0000000000000, which are no C names.
        std::string name;
        if (dumpbin_external_symbol(fields, &name)) {
            if (public_api_symbols.count(name)) found_public_symbol = true;
            if (!exported_symbols.count(name) && is_identifier(name)) define_private(name);
        }
    }

    std::string failure;
    if (!diagnostics.empty()) {
        failure = "it could not read every archive member (for example an LTO object it has no plugin for):" + diagnostics;
    } else if (has_slim_lto) {
        failure = "it lists " + sym_prefix +
                  "__gnu_lto_slim, so the archive holds GCC slim-LTO objects whose symbols this nm cannot read; use an "
                  "nm that loads the GCC LTO plugin, or add -ffat-lto-objects";
    } else if (!found_public_symbol) {
        failure = "it defines none of the public symbols, so " + unfound_reason;
    }
    if (!failure.empty()) {
        std::cerr << "private_namespace: " << listing_source << ": " << failure << "\n";
        return 1;
    }
    std::ofstream header_file(header_path, std::ios::binary);
    header_file << header_text.str();
    header_file.close();
    if (!header_file) {
        std::cerr << "private_namespace: error writing " << header_path << "\n";
        return 1;
    }
    return 0;
}

}  // namespace

int main(int argc, char* argv[]) {
    std::vector<std::string> arguments(argv + 1, argv + argc);
    if (arguments.size() >= 5 && arguments[0] == "list") {
        return run_lister(arguments[1], arguments[2], arguments[3],
                          std::vector<std::string>(arguments.begin() + 4, arguments.end()));
    }
    if (arguments.size() >= 7 && arguments[0] == "header") {
        std::string prefix, export_syms_path;
        std::vector<std::string> unprefixed_public_symbols, wrap_symbols;
        for (std::size_t index = 7; index < arguments.size(); ++index) {
            const std::string& argument = arguments[index];
            if (starts_with(argument, kPrefixFlag)) {
                prefix = argument.substr(kPrefixFlag.size());
            } else if (starts_with(argument, kPublicFlag)) {
                unprefixed_public_symbols.push_back(argument.substr(kPublicFlag.size()));
            } else if (starts_with(argument, kPublicFileFlag)) {
                if (!read_symbols(argument.substr(kPublicFileFlag.size()), &unprefixed_public_symbols)) return 1;
            } else if (starts_with(argument, kWrapFlag)) {
                wrap_symbols.push_back(argument.substr(kWrapFlag.size()));
            } else if (starts_with(argument, kWrapFileFlag)) {
                if (!read_symbols(argument.substr(kWrapFileFlag.size()), &wrap_symbols)) return 1;
            } else if (starts_with(argument, kExportSymsFlag)) {
                export_syms_path = argument.substr(kExportSymsFlag.size());
            } else {
                std::cerr << "private_namespace_gen: unexpected argument " << argument << "\n";
                return 2;
            }
        }
        std::vector<std::string> public_symbols;
        for (const std::string& symbol : unprefixed_public_symbols) public_symbols.push_back(prefix + symbol);
        if (!export_syms_path.empty() && !write_export_syms(export_syms_path, public_symbols, wrap_symbols)) return 1;
        return write_header(arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], arguments[6],
                            public_symbols, wrap_symbols);
    }
    std::cerr << "usage: private_namespace_gen list LISTER LISTING STDERR ARGUMENT...\n"
                 "       private_namespace_gen header HEADER LISTING STDERR SYM_PREFIX LISTING_SOURCE UNFOUND_REASON "
                 "[--prefix=PREFIX] [--public=SYMBOL]... [--public-file=PATH]... [--wrap=SYMBOL]... [--wrap-file=PATH]... "
                 "[--export-syms=PATH]\n";
    return 2;
}
