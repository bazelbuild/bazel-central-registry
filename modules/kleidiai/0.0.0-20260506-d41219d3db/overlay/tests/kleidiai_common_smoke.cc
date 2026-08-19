#include "kai/kai_common.h"

#include <cstddef>

int main() {
  const char* version = kai_get_version();
  if (version == nullptr || version[0] == '\0') {
    return 1;
  }
  return kai_get_datatype_size_in_bytes(kai_dt_f32) == sizeof(float) ? 0 : 1;
}
