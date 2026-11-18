#include <stdio.h>

#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>

#include "rules_cc/cc/runfiles/runfiles.h"

#ifndef BAZEL_CURRENT_REPOSITORY
#define BAZEL_CURRENT_REPOSITORY "_main"
#endif

using rules_cc::cc::runfiles::Runfiles;

int main(void) {
    std::string error = {};
    std::unique_ptr<Runfiles> runfiles(
        Runfiles::CreateForTest(BAZEL_CURRENT_REPOSITORY, &error));

    if (runfiles == nullptr) {
        std::cerr << "Failed to locate runfiles" << error << std::endl;
        return 1;
    }

    const char* env_var = std::getenv("OPENSSL");
    if (!env_var) {
        std::cerr << "No OPENSSL env var set." << std::endl;
        return 1;
    }

    std::string rlocationpath = {env_var};
    std::string openssl = runfiles->Rlocation(rlocationpath);

    if (openssl.empty()) {
        std::cerr << "Could not find runfile: " << rlocationpath << std::endl;
        return 1;
    }

    std::filesystem::path tmpdir(std::getenv("TEST_TMPDIR"));
    std::filesystem::path basename("testdata.txt");
    std::filesystem::path tmpfilePath = tmpdir / basename;

    std::cerr << "Writing temprory file to hash to " << tmpfilePath
              << std::endl;

    std::ofstream tmpfile;
    tmpfile.open(tmpfilePath);
    tmpfile << "European Burmese";
    tmpfile.close();

    std::stringstream command;
    command << openssl << " dgst -sha256 ";
    command << tmpfilePath;

    FILE* outputStream;
#ifdef _WIN32
    outputStream = _popen(command.str().c_str(), "r");
#else
    outputStream = popen(command.str().c_str(), "r");
#endif
    if (!outputStream) {
        std::cerr << "Failed to run command" << std::endl;
        return 1;
    }

    const int MAX_BUFFER = 1024;
    char buffer[MAX_BUFFER];

    std::stringstream output;

    while (!feof(outputStream)) {
        if (fgets(buffer, MAX_BUFFER, outputStream) != NULL) {
            output << buffer;
        }
    }

    std::string sha256(output.str().substr(output.str().length() - 65, 64));
    std::string wantSha256(
        "693d8db7b05e99c6b7a7c0616456039d89c555029026936248085193559a0b5d");

    if (sha256 != wantSha256) {
        std::cerr << "Wrong sha256 - want " << wantSha256 << " got " << sha256
                  << std::endl;
        return 1;
    }

    return 0;
}
