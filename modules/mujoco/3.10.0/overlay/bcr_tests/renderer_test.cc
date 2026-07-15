#include <mujoco/mujoco.h>

#include <cstddef>
#include <cstring>

int main() {
  mjrContext context;
  std::memset(&context, 0xff, sizeof(context));
  mjr_defaultContext(&context);

  const auto* bytes = reinterpret_cast<const unsigned char*>(&context);
  for (std::size_t i = 0; i < sizeof(context); ++i) {
    if (bytes[i] != 0) {
      return 1;
    }
  }
  return 0;
}
