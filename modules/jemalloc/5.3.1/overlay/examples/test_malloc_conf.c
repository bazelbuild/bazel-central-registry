#include <jemalloc/jemalloc.h>
#include <stdio.h>

int main(void) {
  unsigned narenas = 0;
  size_t narenas_size = sizeof(narenas);

  if (mallctl("opt.narenas", &narenas, &narenas_size, NULL, 0) != 0) {
    fprintf(stderr, "mallctl opt.narenas failed\n");
    return 1;
  }

  if (narenas != 1) {
    fprintf(stderr, "expected MALLOC_CONF to set opt.narenas=1, got %u\n", narenas);
    return 1;
  }

  return 0;
}
