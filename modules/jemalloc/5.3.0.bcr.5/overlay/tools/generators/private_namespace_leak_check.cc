// Checks that a static archive defines no symbol outside the public API, the wrapped symbols and private_namespace.h.
// private_namespace_leak_test runs it; its inputs are runfiles keys in the PRIVATE_NAMESPACE_LEAK_* variables.

#include <cstdlib>
#include <iostream>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "private_namespace_listing.h"
#include "rules_cc/cc/runfiles/runfiles.h"

namespace {

using private_namespace::ends_with;
using private_namespace::is_defined_symbol_type;
using private_namespace::is_identifier;
using private_namespace::read_lines;
using private_namespace::read_nm_diagnostics;
using private_namespace::split_fields;
using rules_cc::cc::runfiles::Runfiles;

// An archive member header line, "archive.a:member.o:" or "archive.a(member.o):". Sets *is_cpp_member when the member
// is jemalloc_cpp.o (or jemalloc_cpp.pic.o).
bool is_archive_member_header(const std::string& line, bool* is_cpp_member) {
    std::string member = line;
    if (!ends_with(member, ":")) return false;
    member.pop_back();
    if (ends_with(member, ")")) member.pop_back();
    if (!ends_with(member, ".o")) return false;
    member.resize(member.size() - std::string(".o").size());
    if (ends_with(member, ".pic")) member.resize(member.size() - std::string(".pic").size());
    const std::string cpp_object = "jemalloc_cpp";
    if (!ends_with(member, cpp_object)) {
        *is_cpp_member = false;
    } else if (member.size() == cpp_object.size()) {
        *is_cpp_member = true;
    } else {
        char before = member[member.size() - cpp_object.size() - 1];
        *is_cpp_member = before == '/' || before == '(';
    }
    return true;
}

const char* environment_variable(const char* name) {
    const char* value = std::getenv(name);
    return value ? value : "";
}

// The PRIVATE_NAMESPACE_LEAK_* paths are runfiles keys, so they resolve with or without a runfiles tree.
std::string resolve_runfile(const Runfiles& runfiles, const char* variable) {
    std::string path = runfiles.Rlocation(environment_variable(variable));
    if (path.empty()) {
        std::cerr << "private_namespace: no runfile " << environment_variable(variable) << " for " << variable << "\n";
    }
    return path;
}

// Every symbol the archive defines must be exported (public or wrapped), carry the private prefix with a matching
// private_namespace.h entry, or come from jemalloc_cpp.o: upstream's Makefile lists symbols only from C objects
// (C_SYM_OBJS), so it never namespaces the C++ one.
int check_for_leaks() {
    std::string runfiles_error;
    std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&runfiles_error));
    if (!runfiles) {
        std::cerr << "private_namespace: " << runfiles_error << "\n";
        return 1;
    }
    const std::string listing_name = environment_variable("PRIVATE_NAMESPACE_LEAK_LISTING");
    const std::string sym_prefix = environment_variable("PRIVATE_NAMESPACE_LEAK_SYM_PREFIX");
    const std::string private_prefix = environment_variable("PRIVATE_NAMESPACE_LEAK_PREFIX");
    std::vector<std::string> export_lines, header_lines, listing_lines;
    if (!read_lines(resolve_runfile(*runfiles, "PRIVATE_NAMESPACE_LEAK_EXPORTS"), &export_lines) ||
        !read_lines(resolve_runfile(*runfiles, "PRIVATE_NAMESPACE_LEAK_HEADER"), &header_lines) ||
        !read_lines(resolve_runfile(*runfiles, "PRIVATE_NAMESPACE_LEAK_LISTING"), &listing_lines)) {
        return 1;
    }
    std::set<std::string> exported_symbols, private_symbols, leaked_symbols;
    for (const std::string& symbol : export_lines) exported_symbols.insert(sym_prefix + symbol);
    // "#define NAME JEMALLOC_N(NAME)"
    for (const std::string& line : header_lines) {
        std::vector<std::string> fields = split_fields(line);
        if (fields.size() == 3 && fields[0] == "#define") private_symbols.insert(sym_prefix + private_prefix + fields[1]);
    }
    std::string diagnostics, leak_report;
    if (!read_nm_diagnostics(resolve_runfile(*runfiles, "PRIVATE_NAMESPACE_LEAK_STDERR"), &diagnostics)) return 1;

    bool in_cpp_member = false, has_slim_lto = false, found_exported_symbol = false;
    for (const std::string& line : listing_lines) {
        if (is_archive_member_header(line, &in_cpp_member)) continue;
        // nm -a: "ADDRESS TYPE NAME"
        std::vector<std::string> fields = split_fields(line);
        if (fields.size() != 3) continue;
        const std::string& symbol_type = fields[1];
        const std::string& name = fields[2];
        if (name == sym_prefix + "__gnu_lto_slim") has_slim_lto = true;
        if (is_defined_symbol_type(symbol_type) && is_identifier(name) && !in_cpp_member) {
            if (exported_symbols.count(name)) {
                found_exported_symbol = true;
            } else if (!private_symbols.count(name) && leaked_symbols.insert(name).second) {
                leak_report += "\n  " + name;
            }
        }
    }

    std::string failure;
    if (!diagnostics.empty()) {
        failure = "nm could not read every archive member:" + diagnostics;
    } else if (has_slim_lto) {
        failure = "nm cannot read the GCC slim-LTO objects in the archive";
    } else if (!found_exported_symbol) {
        failure = "nm listed none of the exported symbols";
    } else if (!leak_report.empty()) {
        failure = "these symbols are neither exported nor in private_namespace.h with prefix " + private_prefix + ":" +
                  leak_report;
    }
    if (!failure.empty()) {
        std::cerr << listing_name << ": " << failure << "\n";
        return 1;
    }
    return 0;
}

}  // namespace

int main() { return check_for_leaks(); }
