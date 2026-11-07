/* Distributed under MIT license. See file LICENSE for details. */

#include <stdio.h>

#include "c/common/platform.h"

static int CheckRotation(uint16_t value, size_t count, uint16_t expected) {
  uint16_t actual = BrotliRotateRight16(value, count);
  if (actual != expected) {
    fprintf(stderr,
            "BrotliRotateRight16(%u, %zu) returned %u; expected %u\n",
            (unsigned int)value, count, (unsigned int)actual,
            (unsigned int)expected);
    return 1;
  }
  return 0;
}

int main(void) {
  uint32_t value;
  for (value = 0; value != 65536U; ++value) {
    uint16_t expected = (uint16_t)value;
    size_t count;
    for (count = 0; count != 32; ++count) {
      if (CheckRotation((uint16_t)value, count, expected)) return 1;
      if (count < 16 &&
          CheckRotation((uint16_t)value, BROTLI_SIZE_MAX - 15 + count,
                        expected)) {
        return 1;
      }
      /* Rotate the reference value by one bit for the next count. */
      expected = (uint16_t)(expected / 2U + (expected % 2U) * 32768U);
    }
  }
  return 0;
}
