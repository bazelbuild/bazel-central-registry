#include "dawn/native/DawnNative.h"
#include "dawn/webgpu_cpp.h"

int main() {
    const DawnProcTable& procs = dawn::native::GetProcs();
    if (procs.createInstance == nullptr) {
        return 1;
    }

    dawn::native::Instance instance;
    if (instance.Get() == nullptr) {
        return 2;
    }

    wgpu::RequestAdapterOptions options = {};
#if defined(__APPLE__)
    options.backendType = wgpu::BackendType::Metal;
    const auto adapters = instance.EnumerateAdapters(&options);
#elif defined(_WIN32)
    options.backendType = wgpu::BackendType::D3D12;
    const auto adapters = instance.EnumerateAdapters(&options);
#elif defined(__linux__)
    options.backendType = wgpu::BackendType::Vulkan;
    const auto adapters = instance.EnumerateAdapters(&options);
#else
    const auto adapters = instance.EnumerateAdapters();
#endif
    if (adapters.empty()) {
        return 3;
    }

    if (dawn::native::GetProcMapNamesForTesting().empty()) {
        return 4;
    }

    return 0;
}
