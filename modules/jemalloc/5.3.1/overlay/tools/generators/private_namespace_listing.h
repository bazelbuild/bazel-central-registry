// Parsing shared by private_namespace_gen and private_namespace_leak_check.

#ifndef TOOLS_GENERATORS_PRIVATE_NAMESPACE_LISTING_H
#define TOOLS_GENERATORS_PRIVATE_NAMESPACE_LISTING_H

#include <string>
#include <vector>

namespace private_namespace {

// awk's default field splitting: fields are separated by runs of spaces and tabs.
std::vector<std::string> split_fields(const std::string& line);

bool read_lines(const std::string& path, std::vector<std::string>* lines);

bool ends_with(const std::string& text, const std::string& suffix);

bool starts_with(const std::string& text, const std::string& prefix);

// The nm type letter of a defined symbol: awk's $2 ~ /^[ABCDGRSTVW]$/.
bool is_defined_symbol_type(const std::string& symbol_type);

// awk's $3 ~ /^[A-Za-z0-9_]+$/.
bool is_identifier(const std::string& text);

// The name of the symbol a `dumpbin /SYMBOLS` line defines with external linkage, "... SECTn ... External | NAME", as
// private_symbols.awk matches it: $3 ~ /^SECT[0-9]+/ && $(NF-2) == "External". Sets *name and returns true for such a
// line, given its fields. Two kinds of line awk misses are accepted too, as either symbol would otherwise escape the
// private namespace and the leak check alike:
// - A symbol in a section whose number begins with a letter, as dumpbin numbers sections in hex (SECT9, SECTA, ...,
//   SECTA4).
// - A communal symbol, the uninitialized global cl puts in no section, which dumpbin prints as UNDEF with its size as the
//   value ("055 00000004 UNDEF ... External | ncpus"); nm reports it as C, which awk accepts. An undefined reference
//   prints as UNDEF with the value 0.
bool dumpbin_external_symbol(const std::vector<std::string>& fields, std::string* name);

// Appends each line of nm's stderr at `stderr_path`, other than "...: no symbols", to *diagnostics.
bool read_nm_diagnostics(const std::string& stderr_path, std::string* diagnostics);

}  // namespace private_namespace

#endif
