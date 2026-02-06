#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <ios>
#include <iostream>
#include <string>
#include <vector>

namespace {

constexpr size_t kChunkSize = 8192;

std::string Quote(const uint8_t *data, size_t len) {
  bool last_was_hex = false;
  std::string out;
  out.reserve(len * 4 + 2);
  out.push_back('"');
  for (size_t i = 0; i < len; i++) {
    uint8_t b = data[i];
    bool was_hex = false;
    switch (b) {
      case '\a':
        out.append("\\a");
        break;
      case '\b':
        out.append("\\b");
        break;
      case '\f':
        out.append("\\f");
        break;
      case '\n':
        out.append("\\n");
        break;
      case '\r':
        out.append("\\r");
        break;
      case '\t':
        out.append("\\t");
        break;
      case '\v':
        out.append("\\v");
        break;
      case '"':
        out.append("\\\"");
        break;
      case '\\':
        out.append("\\\\");
        break;
      default: {
        bool is_hex_digit =
            (b >= '0' && b <= '9') || (b >= 'a' && b <= 'f') ||
            (b >= 'A' && b <= 'F');
        if (b >= 32 && b <= 126 && !(last_was_hex && is_hex_digit)) {
          out.push_back(static_cast<char>(b));
        } else {
          char buf[5];
          std::snprintf(buf, sizeof(buf), "\\x%02x", static_cast<unsigned>(b));
          out.append(buf);
          was_hex = true;
        }
        break;
      }
    }
    last_was_hex = was_hex;
  }
  out.push_back('"');
  return out;
}

bool ReadFile(const std::string &path, std::vector<uint8_t> *out) {
  std::ifstream file(path, std::ios::binary);
  if (!file) {
    std::fprintf(stderr, "Error reading %s.\n", path.c_str());
    return false;
  }
  file.seekg(0, std::ios::end);
  std::streampos end = file.tellg();
  if (end < 0) {
    std::fprintf(stderr, "Error reading %s.\n", path.c_str());
    return false;
  }
  out->resize(static_cast<size_t>(end));
  file.seekg(0, std::ios::beg);
  if (!file.read(reinterpret_cast<char *>(out->data()),
                 static_cast<std::streamsize>(out->size()))) {
    std::fprintf(stderr, "Error reading %s.\n", path.c_str());
    return false;
  }
  return true;
}

void WriteHeader(std::ostream &out, const std::vector<std::string> &files) {
  out << "/* clang-format off */\n"
         "#include <stdlib.h>\n"
         "#include <string.h>\n"
         "\n"
         "#include <algorithm>\n"
         "#include <string>\n"
         "\n"
         "\n";
}

void WriteDataBlocks(std::ostream &out,
                     const std::vector<std::vector<uint8_t>> &contents) {
  for (size_t i = 0; i < contents.size(); i++) {
    out << "static const size_t kLen" << i << " = " << contents[i].size()
        << ";\n\n";
    out << "static const char *kData" << i << "[] = {\n";
    const std::vector<uint8_t> &data = contents[i];
    for (size_t offset = 0; offset < data.size(); offset += kChunkSize) {
      size_t chunk = std::min(kChunkSize, data.size() - offset);
      out << "    " << Quote(data.data() + offset, chunk) << ",\n";
    }
    out << "};\n";
  }
}

void WriteLookup(std::ostream &out, const std::vector<std::string> &files) {
  out << "static std::string AssembleString(const char **data, size_t len) {\n"
         "  std::string ret;\n"
         "  for (size_t i = 0; i < len; i += " << kChunkSize << ") {\n"
         "    size_t chunk = std::min(static_cast<size_t>(" << kChunkSize
      << "), len - i);\n"
         "    ret.append(data[i / " << kChunkSize << "], chunk);\n"
         "  }\n"
         "  return ret;\n"
         "}\n"
         "\n"
         "/* Silence -Wmissing-declarations. */\n"
         "std::string GetTestData(const char *path);\n"
         "\n"
         "std::string GetTestData(const char *path) {\n";
  for (size_t i = 0; i < files.size(); i++) {
    out << "  if (strcmp(path, " << Quote(
                                            reinterpret_cast<const uint8_t *>(
                                                files[i].data()),
                                            files[i].size())
        << ") == 0) {\n";
    out << "    return AssembleString(kData" << i << ", kLen" << i << ");\n";
    out << "  }\n";
  }
  out << "  fprintf(stderr, \"File not embedded: %s.\\n\", path);\n"
         "  abort();\n"
         "}\n";
}

}  // namespace

int main(int argc, char **argv) {
  std::string file_list_path;
  std::string out_path;
  std::vector<std::string> positional;

  for (int i = 1; i < argc; i++) {
    if (std::strcmp(argv[i], "-file-list") == 0 && i + 1 < argc) {
      file_list_path = argv[++i];
    } else if (std::strcmp(argv[i], "-out") == 0 && i + 1 < argc) {
      out_path = argv[++i];
    } else {
      positional.emplace_back(argv[i]);
    }
  }

  std::vector<std::string> files;
  if (!file_list_path.empty()) {
    std::ifstream file(file_list_path, std::ios::binary);
    if (!file) {
      std::fprintf(stderr, "Error reading %s.\n", file_list_path.c_str());
      return 1;
    }
    std::string buffer((std::istreambuf_iterator<char>(file)),
                       std::istreambuf_iterator<char>());
    std::string current;
    for (char ch : buffer) {
      if (ch == '\n' || ch == '\r') {
        if (!current.empty()) {
          files.push_back(current);
          current.clear();
        }
      } else {
        current.push_back(ch);
      }
    }
    if (!current.empty()) {
      files.push_back(current);
    }
  }

  files.insert(files.end(), positional.begin(), positional.end());

  if (files.empty()) {
    std::fprintf(stderr, "No input files provided.\n");
    return 1;
  }

  std::ostream *out_stream = &std::cout;
  std::ofstream file_stream;
  if (!out_path.empty()) {
    file_stream.open(out_path, std::ios::binary);
    if (!file_stream) {
      std::fprintf(stderr, "Error creating %s.\n", out_path.c_str());
      return 1;
    }
    out_stream = &file_stream;
  }

  WriteHeader(*out_stream, files);

  std::vector<std::vector<uint8_t>> contents;
  contents.reserve(files.size());
  for (const auto &path : files) {
    std::vector<uint8_t> data;
    if (!ReadFile(path, &data)) {
      return 1;
    }
    contents.push_back(std::move(data));
  }

  WriteDataBlocks(*out_stream, contents);
  WriteLookup(*out_stream, files);

  return 0;
}
