#include <stdio.h>
#include <string.h>
#include <openssl/crypto.h>
#include <openssl/rand.h>
#include <openssl/sha.h>

int main(void) {
  static const unsigned char expected[SHA256_DIGEST_LENGTH] = {
    0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
    0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
    0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
    0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad,
  };
  unsigned char digest[SHA256_DIGEST_LENGTH], random[32];
  if (!FIPS_mode() || strstr(OpenSSL_version(OPENSSL_VERSION), "3.1.0") == NULL) {
    fprintf(stderr, "Expected AWS-LC FIPS 3.1.0\n");
    return 1;
  }
  if (!SHA256((const unsigned char *)"abc", 3, digest) ||
      memcmp(digest, expected, sizeof(expected)) != 0 ||
      !RAND_bytes(random, sizeof(random))) {
    return 1;
  }
  return 0;
}
