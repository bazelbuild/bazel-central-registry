#include <webgpu/webgpu.h>

#include <stdio.h>

int main() {
    WGPUInstance instance = wgpuCreateInstance(nullptr);
    if (instance == nullptr) {
        fputs("wgpuCreateInstance failed.\n", stderr);
        return 1;
    }
    wgpuInstanceRelease(instance);
    return 0;
}
