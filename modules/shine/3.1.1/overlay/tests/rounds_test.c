#include <stdint.h>
#include <stdio.h>

#include "shine/layer3.h"

int main(void) {
  shine_config_t config = {0};
  int16_t left[SHINE_MAX_SAMPLES] = {0};
  int16_t right[SHINE_MAX_SAMPLES] = {0};
  int16_t *channels[] = {left, right};
  int total_written = 0;

  shine_set_config_mpeg_defaults(&config.mpeg);
  config.wave.channels = PCM_STEREO;
  config.wave.samplerate = 44100;
  config.mpeg.mode = STEREO;
  config.mpeg.bitr = 128;

  if (shine_check_config(config.wave.samplerate, config.mpeg.bitr) < 0) {
    fprintf(stderr, "upstream rounds-test audio configuration is unsupported\n");
    return 1;
  }

  shine_t encoder = shine_initialise(&config);
  if (encoder == NULL || shine_samples_per_pass(encoder) > SHINE_MAX_SAMPLES) {
    fprintf(stderr, "could not initialize the upstream stereo encoder\n");
    return 1;
  }

  for (int round = 0; round < 50; ++round) {
    int written = 0;
    unsigned char *encoded = shine_encode_buffer(encoder, channels, &written);
    if (encoded == NULL || written <= 0) {
      fprintf(stderr, "encoding round %d produced no MPEG audio frame\n", round);
      shine_close(encoder);
      return 1;
    }
    total_written += written;
  }

  int flushed = 0;
  shine_flush(encoder, &flushed);
  shine_close(encoder);
  if (total_written + flushed <= 0) {
    fprintf(stderr, "the upstream rounds test produced an empty MPEG stream\n");
    return 1;
  }
  return 0;
}
