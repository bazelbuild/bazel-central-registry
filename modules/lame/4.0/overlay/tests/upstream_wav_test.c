#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "lame/lame.h"

static uint32_t read_little_endian(const unsigned char *bytes) {
  return (uint32_t)bytes[0] | ((uint32_t)bytes[1] << 8) |
         ((uint32_t)bytes[2] << 16) | ((uint32_t)bytes[3] << 24);
}

int main(int argc, char **argv) {
  if (argc != 3) return 1;
  FILE *wav = fopen(argv[1], "rb");
  FILE *reference = fopen(argv[2], "rb");
  if (wav == NULL || reference == NULL) {
    fprintf(stderr, "cannot open LAME's upstream WAV and MP3 fixtures\n");
    return 1;
  }

  unsigned char riff_header[12];
  if (fread(riff_header, sizeof(riff_header), 1, wav) != 1 ||
      memcmp(riff_header, "RIFF", 4) != 0 ||
      memcmp(riff_header + 8, "WAVE", 4) != 0) {
    fprintf(stderr, "invalid original LAME WAV regression fixture\n");
    return 1;
  }

  unsigned char chunk_header[8];
  while (fread(chunk_header, sizeof(chunk_header), 1, wav) == 1 &&
         memcmp(chunk_header, "data", 4) != 0) {
    uint32_t chunk_size = read_little_endian(chunk_header + 4);
    if (fseek(wav, chunk_size + (chunk_size & 1), SEEK_CUR) != 0) return 1;
  }
  if (memcmp(chunk_header, "data", 4) != 0) return 1;

  lame_t encoder = lame_init();
  if (encoder == NULL || lame_set_num_channels(encoder, 2) != 0 ||
      lame_set_in_samplerate(encoder, 44100) != 0 ||
      lame_set_disable_reservoir(encoder, 1) != 0 ||
      lame_init_params(encoder) < 0) {
    fprintf(stderr, "cannot initialize LAME's upstream --nores encode test\n");
    return 1;
  }

  int16_t pcm[2304];
  unsigned char encoded[16384];
  long total_encoded = 0;
  size_t samples;
  while ((samples = fread(pcm, sizeof(int16_t) * 2, 1152, wav)) > 0) {
    int written = lame_encode_buffer_interleaved(encoder, pcm, (int)samples,
                                                encoded, sizeof(encoded));
    if (written < 0) {
      fprintf(stderr, "LAME failed to encode its original WAV fixture\n");
      return 1;
    }
    total_encoded += written;
  }
  int flushed = lame_encode_flush(encoder, encoded, sizeof(encoded));
  lame_close(encoder);
  fclose(wav);
  if (flushed < 0) return 1;
  total_encoded += flushed;

  if (fseek(reference, 0, SEEK_END) != 0) return 1;
  long reference_bytes = ftell(reference);
  fclose(reference);
  if (reference_bytes <= 0 || total_encoded < reference_bytes / 2 ||
      total_encoded > reference_bytes * 2) {
    fprintf(stderr, "unexpected upstream MP3 size: encoded %ld, reference %ld\n",
            total_encoded, reference_bytes);
    return 1;
  }
  return 0;
}
