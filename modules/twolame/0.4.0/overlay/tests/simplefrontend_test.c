#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define main upstream_simplefrontend
#include "../simplefrontend/simplefrontend.c"
#undef main

int main(int argc, char **argv) {
  const char *tmpdir = getenv("TEST_TMPDIR");
  char output_path[1024];
  if (argc != 2 || tmpdir == NULL ||
      snprintf(output_path, sizeof(output_path), "%s/upstream-simple.mp2", tmpdir) >=
          sizeof(output_path)) {
    fprintf(stderr, "missing upstream WAV fixture or Bazel test temporary path\n");
    return 1;
  }

  char *upstream_args[] = {"stwolame", argv[1], output_path, NULL};
  if (upstream_simplefrontend(3, upstream_args) != 0) {
    fprintf(stderr, "the original TwoLAME simple frontend failed\n");
    return 1;
  }
  fflush(NULL);

  FILE *stream = fopen(output_path, "rb");
  if (stream == NULL) {
    perror(output_path);
    return 1;
  }

  const int layer_two_bitrates[] = {
      0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384};
  const int sample_rates[] = {44100, 48000, 32000};
  int frames = 0;
  long total_bytes = 0;
  unsigned char bytes[4];
  while (fread(bytes, sizeof(bytes), 1, stream) == 1) {
    uint32_t header = ((uint32_t)bytes[0] << 24) |
                      ((uint32_t)bytes[1] << 16) |
                      ((uint32_t)bytes[2] << 8) | bytes[3];
    int bitrate_index = (header >> 12) & 15;
    int sample_rate_index = (header >> 10) & 3;
    if ((header & 0xffe00000u) != 0xffe00000u ||
        ((header >> 19) & 3) != 3 || ((header >> 17) & 3) != 2 ||
        bitrate_index == 0 || bitrate_index >= 15 || sample_rate_index >= 3 ||
        layer_two_bitrates[bitrate_index] != 192 ||
        sample_rates[sample_rate_index] != 44100) {
      fprintf(stderr, "invalid upstream MPEG-1 Layer II frame header %d\n", frames);
      fclose(stream);
      return 1;
    }
    int padding = (header >> 9) & 1;
    int frame_size = 144 * layer_two_bitrates[bitrate_index] * 1000 /
                         sample_rates[sample_rate_index] +
                     padding;
    if (fseek(stream, frame_size - 4, SEEK_CUR) != 0) {
      fclose(stream);
      return 1;
    }
    total_bytes += frame_size;
    ++frames;
  }
  fclose(stream);

  if (frames != 22 || total_bytes != 13772) {
    fprintf(stderr, "expected upstream fixture's 22 frames and 13772 bytes; got %d and %ld\n",
            frames, total_bytes);
    return 1;
  }
  return 0;
}
