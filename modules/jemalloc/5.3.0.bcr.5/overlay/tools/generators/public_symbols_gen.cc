// Generates configure.ac's public_syms and wrap_syms lists, public_symbols.txt, and the headers upstream's
// jemalloc_mangle.sh, jemalloc_rename.sh, public_namespace.sh and public_unnamespace.sh print from it. The lists depend
// on the generated configure headers, so they are known only when the build runs.
//
//   public_symbols_gen list OUT [--symbol=NAME | --symbol=NAME:MACRO:HEADER]...
//   public_symbols_gen txt OUT PUBLIC_SYMS [--prefix=PREFIX] [--mangling-map=MAP]
//   public_symbols_gen SCRIPT OUT PUBLIC_SYMBOLS_TXT [--symbol-prefix=PREFIX]
//
// list writes each NAME, one per line in argument order; a NAME with a MACRO only when HEADER defines MACRO, as
// configure.ac appends a symbol to public_syms or wrap_syms in the branch where it defines the macro. HEADER must
// either define or undefine MACRO. SCRIPT is one of jemalloc_mangle.sh, jemalloc_rename.sh, public_namespace.sh and
// public_unnamespace.sh.

#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

namespace {

const std::string kSymbolFlag = "--symbol=";
const std::string kPrefixFlag = "--prefix=";
const std::string kManglingMapFlag = "--mangling-map=";
const std::string kSymbolPrefixFlag = "--symbol-prefix=";

bool starts_with(const std::string& text, const std::string& prefix) {
    return text.compare(0, prefix.size(), prefix) == 0;
}

bool read_file(const std::string& path, std::string* contents) {
    std::ifstream stream(path, std::ios::binary);
    if (!stream) {
        std::cerr << "public_symbols_gen: cannot read " << path << "\n";
        return false;
    }
    std::ostringstream buffer;
    buffer << stream.rdbuf();
    if (stream.bad()) {
        std::cerr << "public_symbols_gen: error reading " << path << "\n";
        return false;
    }
    *contents = buffer.str();
    return true;
}

bool write_file(const std::string& path, const std::string& contents) {
    std::ofstream stream(path, std::ios::binary);
    stream << contents;
    stream.close();
    if (!stream) {
        std::cerr << "public_symbols_gen: error writing " << path << "\n";
        return false;
    }
    return true;
}

// Starlark's text.split(separator): every separator splits, so empty pieces remain.
std::vector<std::string> split(const std::string& text, char separator) {
    std::vector<std::string> pieces;
    std::string::size_type piece_start = 0;
    while (true) {
        std::string::size_type piece_end = text.find(separator, piece_start);
        pieces.push_back(text.substr(piece_start, piece_end == std::string::npos ? std::string::npos
                                                                                   : piece_end - piece_start));
        if (piece_end == std::string::npos) return pieces;
        piece_start = piece_end + 1;
    }
}

// The words of `for word in \`echo ${text} |tr 'from' ' '\``: pieces between spaces and any of `separators`.
std::vector<std::string> words(std::string text, const std::string& separators) {
    for (char& character : text) {
        if (separators.find(character) != std::string::npos) character = ' ';
    }
    std::vector<std::string> nonempty;
    for (const std::string& piece : split(text, ' ')) {
        if (!piece.empty()) nonempty.push_back(piece);
    }
    return nonempty;
}

// $1 and $2 of `echo ${word} |tr ':' ' ' |awk '{print $1}'`, empty when missing.
std::pair<std::string, std::string> name_and_mangled(const std::string& word) {
    std::vector<std::string> fields;
    for (const std::string& field : split(word, ':')) {
        if (!field.empty()) fields.push_back(field);
    }
    fields.resize(fields.size() < 2 ? 2 : fields.size());
    return {fields[0], fields[1]};
}

bool is_identifier_character(char character) {
    return (character >= 'A' && character <= 'Z') || (character >= 'a' && character <= 'z') ||
           (character >= '0' && character <= '9') || character == '_';
}

enum class MacroState { kDefined, kUndefined, kConflicting };

class LineScanner {
   public:
    explicit LineScanner(const std::string& line) : line_(line) {}

    void skip_blanks() {
        while (position_ < line_.size() && (line_[position_] == ' ' || line_[position_] == '\t')) ++position_;
    }

    bool consume(const std::string& text) {
        if (line_.compare(position_, text.size(), text) != 0) return false;
        position_ += text.size();
        return true;
    }

    // A directive keyword followed by at least one blank.
    bool consume_keyword(const std::string& keyword) {
        std::string::size_type start = position_;
        if (!consume(keyword) || position_ >= line_.size() || (line_[position_] != ' ' && line_[position_] != '\t')) {
            position_ = start;
            return false;
        }
        skip_blanks();
        return true;
    }

    std::string identifier() {
        std::string::size_type start = position_;
        while (position_ < line_.size() && is_identifier_character(line_[position_])) ++position_;
        return line_.substr(start, position_ - start);
    }

    bool at_end() const { return position_ >= line_.size(); }

   private:
    const std::string& line_;
    std::string::size_type position_ = 0;
};

// The macros a configured header defines (`#define NAME ...`) or leaves undefined (`/* #undef NAME */`, as configure
// and autoconf_hdr write a template's `#undef NAME` they do not define, or a plain `#undef NAME`).
bool read_header_macros(const std::string& path, std::map<std::string, MacroState>* macros) {
    std::string contents;
    if (!read_file(path, &contents)) return false;
    auto record = [macros](const std::string& name, MacroState state) {
        if (name.empty()) return;
        auto inserted = macros->insert({name, state});
        if (!inserted.second && inserted.first->second != state) inserted.first->second = MacroState::kConflicting;
    };
    for (std::string line : split(contents, '\n')) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        LineScanner scanner(line);
        scanner.skip_blanks();
        if (scanner.consume("/*")) {
            scanner.skip_blanks();
            if (!scanner.consume("#")) continue;
            scanner.skip_blanks();
            if (!scanner.consume_keyword("undef")) continue;
            std::string name = scanner.identifier();
            scanner.skip_blanks();
            if (scanner.consume("*/")) {
                scanner.skip_blanks();
                if (scanner.at_end()) record(name, MacroState::kUndefined);
            }
        } else if (scanner.consume("#")) {
            scanner.skip_blanks();
            if (scanner.consume_keyword("define")) {
                record(scanner.identifier(), MacroState::kDefined);
            } else if (scanner.consume_keyword("undef")) {
                record(scanner.identifier(), MacroState::kUndefined);
            }
        }
    }
    return true;
}

int write_list(const std::string& output_path, const std::vector<std::string>& symbol_arguments) {
    std::map<std::string, std::map<std::string, MacroState>> headers;
    std::string contents;
    for (const std::string& argument : symbol_arguments) {
        std::string::size_type name_end = argument.find(':');
        std::string name = argument.substr(0, name_end);
        if (name_end != std::string::npos) {
            std::string::size_type macro_end = argument.find(':', name_end + 1);
            if (macro_end == std::string::npos) {
                std::cerr << "public_symbols_gen: expected --symbol=NAME:MACRO:HEADER, got " << kSymbolFlag << argument
                          << "\n";
                return 2;
            }
            std::string macro = argument.substr(name_end + 1, macro_end - name_end - 1);
            std::string header_path = argument.substr(macro_end + 1);
            auto header = headers.find(header_path);
            if (header == headers.end()) {
                header = headers.insert({header_path, {}}).first;
                if (!read_header_macros(header_path, &header->second)) return 1;
            }
            auto macro_state = header->second.find(macro);
            if (macro_state == header->second.end()) {
                std::cerr << "public_symbols_gen: " << header_path << " neither defines nor undefines " << macro
                          << ", which decides whether " << name << " is listed\n";
                return 1;
            }
            if (macro_state->second == MacroState::kConflicting) {
                std::cerr << "public_symbols_gen: " << header_path << " both defines and undefines " << macro
                          << ", which decides whether " << name << " is listed\n";
                return 1;
            }
            if (macro_state->second == MacroState::kUndefined) continue;
        }
        contents += name + "\n";
    }
    return write_file(output_path, contents) ? 0 : 1;
}

// configure.ac's AC_CONFIG_COMMANDS for include/jemalloc/internal/public_symbols.txt.
int write_public_symbols(const std::string& output_path, const std::string& public_syms_path,
                         const std::string& prefix, const std::string& mangling_map) {
    std::string public_syms_text;
    if (!read_file(public_syms_path, &public_syms_text)) return 1;
    std::vector<std::string> symbols = words(public_syms_text, "\t\n");
    std::string contents;
    // Entries are split with `echo ${mangling_map} |tr ',' ' '`, so whitespace also separates them, empty fields are
    // skipped, and an entry whose name is not a public symbol is still written.
    for (const std::string& word : words(mangling_map, ",\t\n")) {
        std::pair<std::string, std::string> entry = name_and_mangled(word);
        contents += entry.first + ":" + entry.second + "\n";
        std::vector<std::string> remaining;
        for (const std::string& symbol : symbols) {
            if (symbol != entry.first) remaining.push_back(symbol);
        }
        symbols = remaining;
    }
    for (const std::string& symbol : symbols) contents += symbol + ":" + prefix + symbol + "\n";
    return write_file(output_path, contents) ? 0 : 1;
}

const char kMangleHead[] =
    "/*\n"
    " * By default application code must explicitly refer to mangled symbol names,\n"
    " * so that it is possible to use jemalloc in conjunction with another allocator\n"
    " * in the same application.  Define JEMALLOC_MANGLE in order to cause automatic\n"
    " * name mangling that matches the API prefixing that happened as a result of\n"
    " * --with-mangling and/or --with-jemalloc-prefix configuration settings.\n"
    " */\n"
    "#ifdef JEMALLOC_MANGLE\n"
    "#  ifndef JEMALLOC_NO_DEMANGLE\n"
    "#    define JEMALLOC_NO_DEMANGLE\n"
    "#  endif\n";

const char kMangleMiddleBeforePrefix[] =
    "#endif\n"
    "\n"
    "/*\n"
    " * The ";

const char kMangleMiddleAfterPrefix[] =
    "* macros can be used as stable alternative names for the\n"
    " * public jemalloc API if JEMALLOC_NO_DEMANGLE is defined.  This is primarily\n"
    " * meant for use in jemalloc itself, but it can be used by application code to\n"
    " * provide isolation from the name mangling specified via --with-mangling\n"
    " * and/or --with-jemalloc-prefix.\n"
    " */\n"
    "#ifndef JEMALLOC_NO_DEMANGLE\n";

const char kRenameHead[] =
    "/*\n"
    " * Name mangling for public symbols is controlled by --with-mangling and\n"
    " * --with-jemalloc-prefix.  With default settings the je_ prefix is stripped by\n"
    " * these macro definitions.\n"
    " */\n"
    "#ifndef JEMALLOC_NO_RENAME\n";

using Symbols = std::vector<std::pair<std::string, std::string>>;

std::string render_mangle(const Symbols& symbols, const std::string& symbol_prefix) {
    std::string text = kMangleHead;
    for (const auto& symbol : symbols) text += "#  define " + symbol.first + " " + symbol_prefix + symbol.first + "\n";
    text += kMangleMiddleBeforePrefix + symbol_prefix + kMangleMiddleAfterPrefix;
    for (const auto& symbol : symbols) text += "#  undef " + symbol_prefix + symbol.first + "\n";
    return text + "#endif\n";
}

std::string render_rename(const Symbols& symbols, const std::string&) {
    std::string text = kRenameHead;
    for (const auto& symbol : symbols) text += "#  define je_" + symbol.first + " " + symbol.second + "\n";
    return text + "#endif\n";
}

std::string render_public_namespace(const Symbols& symbols, const std::string&) {
    std::string text;
    for (const auto& symbol : symbols) text += "#define je_" + symbol.first + " JEMALLOC_N(" + symbol.first + ")\n";
    return text;
}

std::string render_public_unnamespace(const Symbols& symbols, const std::string&) {
    std::string text;
    for (const auto& symbol : symbols) text += "#undef je_" + symbol.first + "\n";
    return text;
}

// What the upstream `script` prints for `for nm in \`cat public_symbols.txt\``.
int write_script_output(const std::string& script, const std::string& output_path,
                        const std::string& public_symbols_path, const std::string& symbol_prefix) {
    std::map<std::string, std::string (*)(const Symbols&, const std::string&)> scripts = {
        {"jemalloc_mangle.sh", render_mangle},
        {"jemalloc_rename.sh", render_rename},
        {"public_namespace.sh", render_public_namespace},
        {"public_unnamespace.sh", render_public_unnamespace},
    };
    auto render = scripts.find(script);
    if (render == scripts.end()) return -1;
    std::string public_symbols_text;
    if (!read_file(public_symbols_path, &public_symbols_text)) return 1;
    Symbols symbols;
    for (const std::string& word : words(public_symbols_text, "\t\n")) symbols.push_back(name_and_mangled(word));
    return write_file(output_path, render->second(symbols, symbol_prefix)) ? 0 : 1;
}

// Reads the optional `--flag=value` arguments from `index` on; any other argument is an error.
bool read_flags(const std::vector<std::string>& arguments, std::size_t index,
                std::map<std::string, std::string>* values) {
    for (; index < arguments.size(); ++index) {
        bool known = false;
        for (auto& value : *values) {
            if (starts_with(arguments[index], value.first)) {
                value.second = arguments[index].substr(value.first.size());
                known = true;
                break;
            }
        }
        if (!known) {
            std::cerr << "public_symbols_gen: unexpected argument " << arguments[index] << "\n";
            return false;
        }
    }
    return true;
}

}  // namespace

int main(int argc, char* argv[]) {
    std::vector<std::string> arguments(argv + 1, argv + argc);
    if (arguments.size() >= 2 && arguments[0] == "list") {
        std::vector<std::string> symbol_arguments;
        for (std::size_t index = 2; index < arguments.size(); ++index) {
            if (!starts_with(arguments[index], kSymbolFlag)) {
                std::cerr << "public_symbols_gen: unexpected argument " << arguments[index] << "\n";
                return 2;
            }
            symbol_arguments.push_back(arguments[index].substr(kSymbolFlag.size()));
        }
        return write_list(arguments[1], symbol_arguments);
    }
    if (arguments.size() >= 3 && arguments[0] == "txt") {
        std::map<std::string, std::string> flags = {{kPrefixFlag, ""}, {kManglingMapFlag, ""}};
        if (!read_flags(arguments, 3, &flags)) return 2;
        return write_public_symbols(arguments[1], arguments[2], flags[kPrefixFlag], flags[kManglingMapFlag]);
    }
    if (arguments.size() >= 3) {
        std::map<std::string, std::string> flags = {{kSymbolPrefixFlag, ""}};
        if (read_flags(arguments, 3, &flags)) {
            int status = write_script_output(arguments[0], arguments[1], arguments[2], flags[kSymbolPrefixFlag]);
            if (status >= 0) return status;
        }
    }
    std::cerr << "usage: public_symbols_gen list OUT [--symbol=NAME | --symbol=NAME:MACRO:HEADER]...\n"
                 "       public_symbols_gen txt OUT PUBLIC_SYMS [--prefix=PREFIX] [--mangling-map=MAP]\n"
                 "       public_symbols_gen SCRIPT OUT PUBLIC_SYMBOLS_TXT [--symbol-prefix=PREFIX]\n";
    return 2;
}
