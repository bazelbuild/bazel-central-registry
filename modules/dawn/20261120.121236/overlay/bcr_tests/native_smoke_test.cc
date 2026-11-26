#include <webgpu/webgpu.h>
#include <webgpu/webgpu_cpp.h>

#include <iostream>

int main() {
    WGPUInstance cInstance = wgpuCreateInstance(nullptr);
    if (cInstance == nullptr) {
        std::cerr << "Creating a Dawn instance through the C API failed.\n";
        return 1;
    }
    wgpuInstanceProcessEvents(cInstance);
    wgpuInstanceRelease(cInstance);

    auto instance = wgpu::CreateInstance();
    if (!instance) {
        std::cerr << "Creating a Dawn instance through the C++ API failed.\n";
        return 1;
    }
    instance.ProcessEvents();
    return 0;
}
