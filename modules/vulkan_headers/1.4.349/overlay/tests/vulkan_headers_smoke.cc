#include <vulkan/vulkan.h>
#include <vulkan/vulkan.hpp>

static_assert(VK_HEADER_VERSION > 0);
static_assert(VK_HEADER_VERSION_COMPLETE > 0);

int main() {
  return vk::HeaderVersionComplete > 0 ? 0 : 1;
}
