#include <libzpaq.h>

#include <cstring>
#include <stdexcept>

void libzpaq::error(const char* message) {
  throw std::runtime_error(message);
}

int main() {
  char random_byte;
  libzpaq::random(&random_byte, sizeof(random_byte));

  static const char payload[] =
      "ZPAQ compression round trip. ZPAQ compression round trip. "
      "ZPAQ compression round trip. ZPAQ compression round trip.";

  libzpaq::StringBuffer input;
  libzpaq::StringBuffer archive;
  libzpaq::StringBuffer output;
  input.write(payload, sizeof(payload) - 1);

  libzpaq::compress(&input, &archive, "1");
  libzpaq::decompress(&archive, &output);

  return output.size() == sizeof(payload) - 1 &&
                 std::memcmp(output.data(), payload, sizeof(payload) - 1) == 0
             ? 0 : 1;
}
