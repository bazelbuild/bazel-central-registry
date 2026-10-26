#ifdef INCLUDE_ZLIB_WITH_QUOTES
#include "zlib.h"
#else
#include <zlib.h>
#endif

#include <string.h>

int main(void) {
  static const char input[] = "hello, hello, hello, hello!";
  Bytef compressed[128];
  Bytef decompressed[sizeof(input)];
  uLongf compressed_len = sizeof(compressed);
  uLongf decompressed_len = sizeof(decompressed);

  if (compress(compressed, &compressed_len, (const Bytef *)input,
               sizeof(input)) != Z_OK) {
    return 1;
  }
  if (uncompress(decompressed, &decompressed_len, compressed,
                 compressed_len) != Z_OK) {
    return 2;
  }
  if (decompressed_len != sizeof(input) ||
      memcmp(input, decompressed, sizeof(input)) != 0) {
    return 3;
  }
  return 0;
}
