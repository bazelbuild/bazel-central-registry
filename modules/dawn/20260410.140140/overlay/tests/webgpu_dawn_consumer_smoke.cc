#include "dawn/native/DawnNative.h"

int main() {
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
