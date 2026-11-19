/* Round-trip through every codec this CPU supports (forced via flags), and
 * against a known encoding. Forcing a codec the CPU lacks is undefined
 * behaviour (base64 does not check), so forced codecs are gated on CPU
 * features. */

#include <stdio.h>
#include <string.h>

#include <libbase64.h>

static int roundtrip(int flags, const char* label) {
  const char* input = "Tracy profiler: the quick brown fox jumps over the lazy dog 0123456789";
  char encoded[256];
  char decoded[256];
  size_t enc_len = 0, dec_len = 0;
  base64_encode(input, strlen(input), encoded, &enc_len, flags);
  if (base64_decode(encoded, enc_len, decoded, &dec_len, flags) != 1) {
    printf("%-8s: decode failed\n", label);
    return 1;
  }
  const int ok = dec_len == strlen(input) && memcmp(decoded, input, dec_len) == 0;
  printf("%-8s: %s\n", label, ok ? "ok" : "MISMATCH");
  return ok ? 0 : 1;
}

int main(void) {
  char out[16];
  size_t out_len = 0;
  base64_encode("Man", 3, out, &out_len, 0);
  if (out_len != 4 || memcmp(out, "TWFu", 4) != 0) return 1;

  setvbuf(stdout, NULL, _IONBF, 0);
  int rc = 0;
  rc |= roundtrip(0, "auto");
  rc |= roundtrip(BASE64_FORCE_PLAIN, "plain");
#if (defined(__x86_64__) || defined(_M_X64)) && defined(__GNUC__)
  __builtin_cpu_init();
  if (__builtin_cpu_supports("ssse3")) rc |= roundtrip(BASE64_FORCE_SSSE3, "ssse3");
  if (__builtin_cpu_supports("sse4.1")) rc |= roundtrip(BASE64_FORCE_SSE41, "sse41");
  if (__builtin_cpu_supports("sse4.2")) rc |= roundtrip(BASE64_FORCE_SSE42, "sse42");
  if (__builtin_cpu_supports("avx")) rc |= roundtrip(BASE64_FORCE_AVX, "avx");
  if (__builtin_cpu_supports("avx2")) rc |= roundtrip(BASE64_FORCE_AVX2, "avx2");
  if (__builtin_cpu_supports("avx512vl") && __builtin_cpu_supports("avx512vbmi")) {
    rc |= roundtrip(BASE64_FORCE_AVX512, "avx512");
  }
#elif defined(__aarch64__) || defined(_M_ARM64)
  rc |= roundtrip(BASE64_FORCE_NEON64, "neon64");
#endif
  return rc;
}
