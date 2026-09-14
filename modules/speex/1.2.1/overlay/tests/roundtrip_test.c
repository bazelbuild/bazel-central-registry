#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define main upstream_speex_roundtrip
#if defined(SPEEX_TEST_WIDEBAND)
#include "../libspeex/testenc_wb.c"
#define UPSTREAM_SUCCESS 1
#elif defined(SPEEX_TEST_ULTRA_WIDEBAND)
#include "../libspeex/testenc_uwb.c"
#define UPSTREAM_SUCCESS 1
#else
#include "../libspeex/testenc.c"
#define UPSTREAM_SUCCESS 0
#endif
#undef main

int main(void) {
  const char *tmpdir = getenv("TEST_TMPDIR");
  char input_path[1024];
  char output_path[1024];
  if (tmpdir == NULL ||
      snprintf(input_path, sizeof(input_path), "%s/speex-input.pcm", tmpdir) >=
          sizeof(input_path) ||
      snprintf(output_path, sizeof(output_path), "%s/speex-output.pcm", tmpdir) >=
          sizeof(output_path)) {
    fprintf(stderr, "missing or excessively long Bazel test temporary path\n");
    return 1;
  }

  FILE *input = fopen(input_path, "wb");
  if (input == NULL) {
    perror(input_path);
    return 1;
  }
  for (int i = 0; i < 640 * 16; ++i) {
    int16_t sample = (int16_t)((i * 97) % 16384 - 8192);
    if (fwrite(&sample, sizeof(sample), 1, input) != 1) {
      fclose(input);
      return 1;
    }
  }
  fclose(input);

  char *upstream_args[] = {"speex-upstream-test", input_path, output_path, NULL};
  if (upstream_speex_roundtrip(3, upstream_args) != UPSTREAM_SUCCESS) {
    fprintf(stderr, "the original Speex encode/decode test failed\n");
    return 1;
  }

  FILE *output = fopen(output_path, "rb");
  if (output == NULL || fgetc(output) == EOF) {
    fprintf(stderr, "the original Speex test did not decode any PCM audio\n");
    if (output != NULL) fclose(output);
    return 1;
  }
  fclose(output);
  return 0;
}
