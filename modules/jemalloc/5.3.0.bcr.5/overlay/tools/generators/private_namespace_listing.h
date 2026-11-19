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

// Appends each line of nm's stderr at `stderr_path`, other than "...: no symbols", to *diagnostics.
bool read_nm_diagnostics(const std::string& stderr_path, std::string* diagnostics);

}  // namespace private_namespace

#endif
