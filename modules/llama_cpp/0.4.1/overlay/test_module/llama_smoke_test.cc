// Links libllama and exercises the parts of the public API that work without
// model weights, which is enough to prove the module builds and links.

#include <cstdio>
#include <cstdlib>

#include "llama.h"

int main() {
    llama_backend_init();

    const char *info = llama_print_system_info();
    if (info == nullptr) {
        std::fprintf(stderr, "llama_print_system_info() returned null\n");
        return EXIT_FAILURE;
    }
    std::printf("llama system info: %s\n", info);

    if (llama_max_devices() == 0 && llama_time_us() == 0) {
        std::fprintf(stderr, "llama runtime did not initialize\n");
        return EXIT_FAILURE;
    }

    llama_backend_free();
    return EXIT_SUCCESS;
}
