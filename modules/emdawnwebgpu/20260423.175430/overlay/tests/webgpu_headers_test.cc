#include <webgpu/webgpu.h>
#include <webgpu/webgpu_cpp.h>

int main() {
    WGPUStringView view = WGPU_STRING_VIEW_INIT;
    wgpu::TextureFormat format = wgpu::TextureFormat::RGBA8Unorm;
    return (view.data == nullptr && format != wgpu::TextureFormat::Undefined) ? 0 : 1;
}
