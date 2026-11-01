// Assemble a Bazel tree artifact using only explicitly declared input files.
#include <utime.h>

#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>
#include <unordered_set>

namespace fs = std::filesystem;

namespace {
constexpr auto kFileMode = fs::perms::owner_read | fs::perms::owner_write |
                           fs::perms::group_read | fs::perms::others_read;
constexpr auto kExecutableMode = kFileMode | fs::perms::owner_exec |
                                 fs::perms::group_exec | fs::perms::others_exec;

void SetTime(const fs::path& path) {
  const utimbuf epoch = {0, 0};
  if (utime(path.c_str(), &epoch) != 0)
    throw std::runtime_error("Cannot set timestamp: " + path.string());
}
}  // namespace

int main(int argc, char** argv) {
  try {
    if (argc < 2 || (argc - 2) % 3 != 0)
      throw std::runtime_error("Usage: runtime_tool output [destination mode source]...");
    const fs::path output(argv[1]);
    fs::create_directories(output);
    std::unordered_set<std::string> destinations;
    for (int i = 2; i < argc; i += 3) {
      const fs::path relative(argv[i]);
      const std::string mode(argv[i + 1]);
      const fs::path source(argv[i + 2]);
      if (relative.empty() || relative.is_absolute())
        throw std::runtime_error("Invalid destination: " + relative.string());
      for (const auto& component : relative) {
        if (component == ".." || component == ".")
          throw std::runtime_error("Invalid destination: " + relative.string());
      }
      if (!destinations.insert(relative.generic_string()).second)
        throw std::runtime_error("Duplicate destination: " + relative.string());
      if (mode != "0644" && mode != "0755")
        throw std::runtime_error("Invalid mode: " + mode);
      if (!fs::is_regular_file(source))
        throw std::runtime_error("Input is not a regular file: " + source.string());
      const auto destination = output / relative;
      fs::create_directories(destination.parent_path());
      // Follow input symlinks so the installed tree has no references back into
      // the execution root or to shared objects with platform-specific names.
      fs::copy_file(source, destination, fs::copy_options::overwrite_existing);
      fs::permissions(destination, mode == "0755" ? kExecutableMode : kFileMode);
      SetTime(destination);
    }
    for (const auto& entry : fs::recursive_directory_iterator(output)) {
      if (entry.is_directory()) {
        fs::permissions(entry.path(), kExecutableMode);
        SetTime(entry.path());
      }
    }
    fs::permissions(output, kExecutableMode);
    SetTime(output);
    return 0;
  } catch (const std::exception& error) {
    std::cerr << "ngspice runtime assembly: " << error.what() << '\n';
    return 1;
  }
}
