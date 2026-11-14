// Compiles the VMA implementation and exercises the virtual allocator, which needs
// no Vulkan device. No Vulkan functions are fetched, so the Vulkan loader is not linked.
#define VMA_STATIC_VULKAN_FUNCTIONS 0
#define VMA_DYNAMIC_VULKAN_FUNCTIONS 0
#define VMA_IMPLEMENTATION
#include <vk_mem_alloc.h>

int main() {
    VmaVirtualBlockCreateInfo block_info = {};
    block_info.size = 1 << 20;
    VmaVirtualBlock block = VK_NULL_HANDLE;
    if (vmaCreateVirtualBlock(&block_info, &block) != VK_SUCCESS) {
        return 1;
    }

    VmaVirtualAllocationCreateInfo alloc_info = {};
    alloc_info.size = 4096;
    alloc_info.alignment = 256;
    VmaVirtualAllocation alloc = VK_NULL_HANDLE;
    VkDeviceSize offset = 1;
    const bool allocated = vmaVirtualAllocate(block, &alloc_info, &alloc, &offset) == VK_SUCCESS;
    const bool ok = allocated && offset % 256 == 0 && vmaIsVirtualBlockEmpty(block) == VK_FALSE;

    vmaVirtualFree(block, alloc);
    const bool empty = vmaIsVirtualBlockEmpty(block) == VK_TRUE;
    vmaDestroyVirtualBlock(block);
    return ok && empty ? 0 : 1;
}
