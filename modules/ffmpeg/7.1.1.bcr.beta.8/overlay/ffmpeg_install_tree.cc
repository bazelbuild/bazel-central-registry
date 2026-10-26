#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

namespace fs = std::filesystem;

fs::path strip_prefix(const fs::path& file, const fs::path& prefix) {
    auto file_str = file.string();
    auto prefix_str = prefix.string();
    if (file_str.substr(0, prefix_str.size()) == prefix_str) {
        auto result = file_str.substr(prefix_str.size());
        if (!result.empty() && (result[0] == '/' || result[0] == '\\'))
            result = result.substr(1);
        return fs::path(result);
    }
    return file;
}

int copy_file(const fs::path& dest_dir, const fs::path& file,
              const fs::path& prefix) {
    fs::path clean_filepath = strip_prefix(file, prefix);
    fs::path target_dir = dest_dir / clean_filepath.parent_path();

    fs::create_directories(target_dir);
    fs::copy(file, target_dir, fs::copy_options::overwrite_existing);
    return 0;
}

struct ManifestEntry {
    std::string dest_dir;
    std::string file;
    std::string prefix;
};

std::vector<ManifestEntry> parse_manifest(const fs::path& manifest_path) {
    std::vector<ManifestEntry> entries;
    std::ifstream in(manifest_path);
    if (!in) {
        std::cerr << "Failed to open manifest: " << manifest_path << std::endl;
        return entries;
    }

    std::string line;
    while (std::getline(in, line)) {
        if (line.empty()) continue;

        auto first_tab = line.find('\t');
        auto second_tab = line.find('\t', first_tab + 1);
        if (first_tab == std::string::npos || second_tab == std::string::npos) {
            std::cerr << "Malformed manifest line: " << line << std::endl;
            continue;
        }

        entries.push_back({
            line.substr(0, first_tab),
            line.substr(first_tab + 1, second_tab - first_tab - 1),
            line.substr(second_tab + 1),
        });
    }
    return entries;
}

int main(int argc, char* argv[]) {
    if (argc == 2) {
        auto entries = parse_manifest(argv[1]);
        if (entries.empty()) {
            std::cerr << "No entries found in manifest: " << argv[1]
                      << std::endl;
            return 1;
        }
        for (const auto& e : entries) {
            int rc = copy_file(e.dest_dir, e.file, e.prefix);
            if (rc != 0) return rc;
        }
        return 0;
    }

    if (argc == 4) {
        return copy_file(argv[1], argv[2], argv[3]);
    }

    std::cerr << "Usage: " << argv[0] << " <manifest_file>" << std::endl;
    std::cerr << "       " << argv[0] << " /dest/dir file prefix" << std::endl;
    return 1;
}
