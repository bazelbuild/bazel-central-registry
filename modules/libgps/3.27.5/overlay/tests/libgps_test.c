#include "include/gps.h"

int main(void) {
  const char* mask = gps_maskdump(0);
  return (mask != 0) ? 0 : 1;
}
