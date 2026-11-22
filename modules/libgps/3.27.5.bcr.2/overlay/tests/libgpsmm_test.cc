#include <libgpsmm.h>

int main() {
  // GPSD_LOCAL_FILE makes libgps read a plain file instead of a daemon socket,
  // so a real gpsmm object exercises the documented C++ API with no gpsd,
  // socket or network involved.
  gpsmm gps(GPSD_LOCAL_FILE, "/dev/null");
  if (!gps.is_open()) {
    return 1;  // constructor failed to open
  }
  if (nullptr == gps.stream(WATCH_ENABLE)) {
    return 1;  // local-file streams are read-only, so this always succeeds
  }
  (void)gps.read();  // /dev/null is an immediate EOF
  return 0;
}
