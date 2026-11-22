/* Shared helpers for the on-GPU render tests. Include after the GL header. */
#ifndef LIBGLVND_TESTS_RENDER_COMMON_H_
#define LIBGLVND_TESTS_RENDER_COMMON_H_

#include <dlfcn.h> /* dladdr/Dl_info: needs _GNU_SOURCE, set in BUILD.bazel */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(cond, ...)                                       \
    do {                                                       \
        if (!(cond)) {                                         \
            fprintf(stderr, "FAIL %s:%d: ", __FILE__, __LINE__); \
            fprintf(stderr, __VA_ARGS__);                      \
            fprintf(stderr, "\n");                             \
            exit(1);                                           \
        }                                                      \
    } while (0)

/* Fails if `symbol` resolves into a libglvnd stub rather than the system
 * library: the stubs must never be loaded at runtime. Looked up by name
 * (not &symbol), which in a non-PIE executable may point at a local PLT. */
static void check_real_library(const char* symbol) {
    void* fn = dlsym(RTLD_DEFAULT, symbol);
    CHECK(fn != NULL, "%s not found in any loaded library", symbol);
    Dl_info info;
    CHECK(dladdr(fn, &info) && info.dli_fname, "dladdr failed for %s", symbol);
    printf("%-20s resolved from %s\n", symbol, info.dli_fname);
    CHECK(strstr(info.dli_fname, "_stub") == NULL && strstr(info.dli_fname, "libdir") == NULL &&
              strstr(info.dli_fname, "_solib") == NULL,
          "%s was loaded from a link-time stub (%s)", symbol, info.dli_fname);
}

/* Clears to a known color, reads a pixel back and checks it. Works on
 * desktop GL, GLES 1.x and GLES 2.0+. */
static void clear_and_verify(void) {
    printf("GL_VENDOR   = %s\n", (const char*)glGetString(GL_VENDOR));
    printf("GL_RENDERER = %s\n", (const char*)glGetString(GL_RENDERER));
    printf("GL_VERSION  = %s\n", (const char*)glGetString(GL_VERSION));
    CHECK(glGetString(GL_VERSION) != NULL, "glGetString(GL_VERSION) returned NULL");

    glClearColor(0.25f, 0.5f, 0.75f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glFinish();
    unsigned char px[4] = {0, 0, 0, 0};
    glReadPixels(4, 4, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, px);
    CHECK(glGetError() == GL_NO_ERROR, "GL error after glReadPixels");
    const int want[4] = {64, 128, 191, 255};
    for (int i = 0; i < 4; ++i) {
        CHECK(abs(px[i] - want[i]) <= 2, "pixel = (%d,%d,%d,%d), want ~(64,128,191,255)", px[0], px[1],
              px[2], px[3]);
    }
    printf("readback  = (%d,%d,%d,%d) OK\n", px[0], px[1], px[2], px[3]);
}

#endif /* LIBGLVND_TESTS_RENDER_COMMON_H_ */
