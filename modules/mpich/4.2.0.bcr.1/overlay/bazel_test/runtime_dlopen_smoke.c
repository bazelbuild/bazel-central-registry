#include <dlfcn.h>
#include <stdio.h>

int main(int argc, char **argv) {
    void *handle;

    if (argc != 2) {
        return 1;
    }
    handle = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (handle == NULL) {
        fprintf(stderr, "%s\n", dlerror());
        return 2;
    }
    if (dlsym(handle, "MPI_Init") == NULL ||
        dlsym(handle, "MPI_Finalize") == NULL ||
        dlsym(handle, "MPI_File_open") == NULL) {
        return 3;
    }
    return dlclose(handle) == 0 ? 0 : 4;
}
