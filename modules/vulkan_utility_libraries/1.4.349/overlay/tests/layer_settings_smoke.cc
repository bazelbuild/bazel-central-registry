#include <vulkan/layer/vk_layer_settings.hpp>

#include <vector>

int main() {
    std::vector<bool> values;
    VkuLayerSettingSet layer_setting_set = VK_NULL_HANDLE;
    VkResult result = vkuGetLayerSettingValues(layer_setting_set, "missing-setting", values);
    (void)result;
    return 0;
}
