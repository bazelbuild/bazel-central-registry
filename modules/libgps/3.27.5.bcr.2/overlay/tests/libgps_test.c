#include "gps.h"

int main(void) {
  const char* mask = gps_maskdump(0);
  const timespec_t timestamp = iso8601_to_timespec("1970-01-01T00:00:00.125Z");
  if (mask == 0 || timestamp.tv_sec != 0 || timestamp.tv_nsec != 125000000) {
    return 1;
  }
  return 0;
}
