#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <memory>
#include <regex>
#include <sstream>
#include <string>

#include "rules_cc/cc/runfiles/runfiles.h"

using rules_cc::cc::runfiles::Runfiles;

int main(int argc, char* argv[]) {
    std::string error;
    std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
    if (runfiles == nullptr) {
        std::cerr << "failed to create runfiles: " << error << std::endl;
        return 1;
    }

    // Resolve paths from environment variables.
    const char* dnsmasq_rlocation = std::getenv("DNSMASQ_RLOCATIONPATH");
    const char* module_rlocation = std::getenv("MODULE_BAZEL_RLOCATIONPATH");
    if (dnsmasq_rlocation == nullptr || module_rlocation == nullptr) {
        std::cerr << "DNSMASQ_RLOCATIONPATH and MODULE_BAZEL_RLOCATIONPATH "
                     "must be set"
                  << std::endl;
        return 1;
    }

    std::string dnsmasq_path = runfiles->Rlocation(dnsmasq_rlocation);
    std::string module_bazel_path = runfiles->Rlocation(module_rlocation);
    if (dnsmasq_path.empty() || module_bazel_path.empty()) {
        std::cerr << "failed to resolve runfiles" << std::endl;
        return 1;
    }

    // Read MODULE.bazel and extract the module version.
    std::ifstream module_file(module_bazel_path);
    if (!module_file.is_open()) {
        std::cerr << "failed to open " << module_bazel_path << std::endl;
        return 1;
    }
    std::ostringstream buf;
    buf << module_file.rdbuf();
    std::string module_content = buf.str();

    // Match version = "..." inside the module() call.
    std::regex version_re(R"re(module\s*\([^)]*version\s*=\s*"([^"]+)")re");
    std::smatch match;
    if (!std::regex_search(module_content, match, version_re)) {
        std::cerr << "could not find module version in " << module_bazel_path
                  << std::endl;
        return 1;
    }
    std::string version = match[1].str();

    // Strip any .bcr.N suffix -- the upstream binary only reports the
    // base version (e.g. "2.92"), not the BCR packaging revision.
    version = std::regex_replace(version, std::regex(R"(\.bcr\.\d+$)"), "");

    // Run dnsmasq --version and capture its output.
    std::string cmd = dnsmasq_path + " --version";
    FILE* fp = popen(cmd.c_str(), "r");
    if (!fp) {
        std::perror("popen");
        return 1;
    }
    char line[4096];
    std::string output;
    while (std::fgets(line, sizeof(line), fp)) {
        output += line;
    }
    int status = pclose(fp);
    if (status != 0) {
        std::cerr << "dnsmasq --version exited with status " << status
                  << std::endl;
        return 1;
    }

    // Assert the output contains "Dnsmasq version <version>".
    std::string expected = "Dnsmasq version " + version;
    if (output.find(expected) == std::string::npos) {
        std::cerr << "expected '" << expected << "' in output:\n"
                  << output << std::endl;
        return 1;
    }

    std::cout << output;
    return 0;
}
