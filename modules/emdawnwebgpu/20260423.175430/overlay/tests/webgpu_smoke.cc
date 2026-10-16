#include <webgpu/webgpu.h>

int main() {
    WGPUInstance instance = wgpuCreateInstance(nullptr);
    if (instance != nullptr) {
        wgpuInstanceRelease(instance);
    }
    return 0;
}
