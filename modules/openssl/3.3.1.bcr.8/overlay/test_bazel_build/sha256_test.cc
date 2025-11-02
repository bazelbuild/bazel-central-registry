#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdio.h>

int main(void) {
  std::filesystem::path tmpdir(std::getenv("TEST_TMPDIR"));
  std::filesystem::path basename("testdata.txt");
  std::filesystem::path tmpfilePath = tmpdir / basename;

  std::cerr << "Writing temprory file to hash to " << tmpfilePath << std::endl;

  std::ofstream tmpfile;
  tmpfile.open(tmpfilePath);
  tmpfile << "European Burmese";
  tmpfile.close();

  std::stringstream command;
  command << "openssl dgst -sha256 ";
  command << tmpfilePath;

  FILE *outputStream;
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
  std::string wantSha256("693d8db7b05e99c6b7a7c0616456039d89c555029026936248085193559a0b5d");

  if (sha256 != wantSha256) {
    std::cerr << "Wrong sha256 - want " << wantSha256 << " got " << sha256 << std::endl;
    return 1;
  }

  return 0;
}
