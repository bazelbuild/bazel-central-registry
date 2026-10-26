#include <libzpaq.h>

namespace {

struct ZpaqError {};

}  // namespace

void libzpaq::error(const char*) {
  throw ZpaqError();
}

int main() {
  // A valid ZPAQ locator tag and block signature followed by an unsupported
  // level byte. This must call the consumer-provided libzpaq::error() hook.
  static const unsigned char malformed_archive[] = {
      0x37, 0x6b, 0x53, 0x74, 0xa0, 0x31, 0x83,
      0xd3, 0x8c, 0xb2, 0x28, 0xb0, 0xd3, 0x7a,
      0x50, 0x51, 0x00,
  };

  libzpaq::StringBuffer input;
  libzpaq::StringBuffer output;
  input.write(reinterpret_cast<const char*>(malformed_archive),
              sizeof(malformed_archive));

  try {
    libzpaq::decompress(&input, &output);
  } catch (const ZpaqError&) {
    return 0;
  } catch (...) {
    return 2;
  }
  return 1;
}
