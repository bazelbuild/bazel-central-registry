#include "private_namespace_listing.h"

#include <fstream>
#include <iostream>

namespace private_namespace {

std::vector<std::string> split_fields(const std::string& line) {
    std::vector<std::string> fields;
    std::string::size_type field_start = 0;
    while (true) {
        field_start = line.find_first_not_of(" \t", field_start);
        if (field_start == std::string::npos) break;
        std::string::size_type field_end = line.find_first_of(" \t", field_start);
        fields.push_back(
            line.substr(field_start, field_end == std::string::npos ? std::string::npos : field_end - field_start));
        if (field_end == std::string::npos) break;
        field_start = field_end;
    }
    return fields;
}

bool read_lines(const std::string& path, std::vector<std::string>* lines) {
    std::ifstream stream(path, std::ios::binary);
    if (!stream) {
        std::cerr << "private_namespace: cannot read " << path << "\n";
        return false;
    }
    // Read in binary so every platform sees the same bytes, then drop the CR of a CRLF line ending, which link /DUMP
    // and other Windows tools write.
    std::string line;
    while (std::getline(stream, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        lines->push_back(line);
    }
    if (stream.bad()) {
        std::cerr << "private_namespace: error reading " << path << "\n";
        return false;
    }
    return true;
}

bool ends_with(const std::string& text, const std::string& suffix) {
    return text.size() >= suffix.size() && text.compare(text.size() - suffix.size(), suffix.size(), suffix) == 0;
}

bool starts_with(const std::string& text, const std::string& prefix) {
    return text.compare(0, prefix.size(), prefix) == 0;
}

bool is_defined_symbol_type(const std::string& symbol_type) {
    return symbol_type.size() == 1 && std::string("ABCDGRSTVW").find(symbol_type[0]) != std::string::npos;
}

bool is_identifier(const std::string& text) {
    if (text.empty()) return false;
    for (char character : text) {
        bool allowed = (character >= 'A' && character <= 'Z') || (character >= 'a' && character <= 'z') ||
                       (character >= '0' && character <= '9') || character == '_';
        if (!allowed) return false;
    }
    return true;
}

bool dumpbin_external_symbol(const std::vector<std::string>& fields, std::string* name) {
    std::size_t field_count = fields.size();
    if (field_count < 3 || fields[field_count - 3] != "External") return false;
    const std::string& section = fields[2];
    bool in_section = starts_with(section, "SECT") && section.size() > 4 &&
                      section.find_first_not_of("0123456789ABCDEF", 4) == std::string::npos;
    bool communal = section == "UNDEF" && fields[1].find_first_not_of('0') != std::string::npos;
    if (!in_section && !communal) return false;
    *name = fields[field_count - 1];
    return true;
}

// Binutils nm reports an archive member it cannot read on stderr yet exits 0, so stderr other than "no symbols" fails.
bool read_nm_diagnostics(const std::string& stderr_path, std::string* diagnostics) {
    std::vector<std::string> lines;
    if (!read_lines(stderr_path, &lines)) return false;
    for (const std::string& line : lines) {
        if (!ends_with(line, ": no symbols")) *diagnostics += "\n  " + line;
    }
    return true;
}

}  // namespace private_namespace
