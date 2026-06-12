#include "dawn/native/DawnNative.h"
#include "dawn/native/OpenGLBackend.h"

int main() {
    static_assert(sizeof(dawn::native::opengl::GLuint) == sizeof(unsigned int));

    const DawnProcTable& procs = dawn::native::GetProcs();
    if (procs.createInstance == nullptr) {
        return 1;
    }

    dawn::native::Instance instance;
    if (instance.Get() == nullptr) {
        return 2;
    }

    if (dawn::native::GetProcMapNamesForTesting().empty()) {
        return 3;
    }

    return 0;
}
