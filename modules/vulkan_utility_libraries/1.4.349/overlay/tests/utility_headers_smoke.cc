#include <vulkan/vk_enum_string_helper.h>
#include <vulkan/utility/vk_dispatch_table.h>
#include <vulkan/utility/vk_struct_helper.hpp>

static_assert(VK_HEADER_VERSION > 0);

int main() {
    VkApplicationInfo app_info = vku::InitStructHelper();
    (void)app_info;
    (void)string_VkResult(VK_SUCCESS);

    VkuInstanceDispatchTable dispatch_table = {};
    (void)dispatch_table;
    return 0;
}
