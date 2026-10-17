#include <ares.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

static int check_random_sequence(void) {
  int status = ares_library_init(ARES_LIB_INIT_ALL);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "c-ares initialization: %s\n", ares_strerror(status));
    return 1;
  }

  int expected[16];
  srand(42);
  for (size_t i = 0; i < sizeof(expected) / sizeof(expected[0]); ++i) {
    expected[i] = rand();
  }
  srand(42);

  struct ares_options options = {0};
  ares_channel_t* channel = NULL;
  options.resolvconf_path = "/dev/null";
  status = ares_init_options(&channel, &options, ARES_OPT_RESOLVCONF);
  if (status != ARES_SUCCESS) {
    fprintf(stderr, "channel initialization: %s\n", ares_strerror(status));
    ares_library_cleanup();
    return 1;
  }
  ares_destroy(channel);

  for (size_t i = 0; i < sizeof(expected) / sizeof(expected[0]); ++i) {
    if (rand() != expected[i]) {
      fprintf(stderr, "channel creation changed libc's random sequence at index %zu\n", i);
      ares_library_cleanup();
      return 1;
    }
  }

  ares_library_cleanup();
  return 0;
}

int main(void) {
  int result = check_random_sequence();
  if (result != 0) {
    return result;
  }
  fputs("getrandom: ordinary channel initialization preserved libc random sequence\n", stderr);
  return 0;
}
