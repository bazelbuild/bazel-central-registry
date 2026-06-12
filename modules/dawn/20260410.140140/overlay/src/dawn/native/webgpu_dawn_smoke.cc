#include "dawn/native/DawnNative.h"

int main() {
    const DawnProcTable* procs = &dawn::native::GetProcs();
    if (procs == nullptr) {
        return 1;
    }

    dawn::native::Instance instance;
    if (instance.Get() == nullptr) {
        return 2;
    }

    auto adapters = instance.EnumerateAdapters();
    if (adapters.empty()) {
        return 3;
    }

    if (dawn::native::GetProcMapNamesForTesting().empty()) {
        return 4;
    }

    return 0;
}
