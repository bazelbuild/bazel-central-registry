/*
 * Where the C library has pvalloc, jemalloc.h defines JEMALLOC_OVERRIDE_PVALLOC and jemalloc exports pvalloc too, as
 * configure does. Otherwise the C library's pvalloc would hand out memory from its own heap, which the replaced free
 * then passes to jemalloc. glibc has pvalloc, so there the override must be defined. thread.allocated counts the bytes
 * this thread allocates through jemalloc.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#define JEMALLOC_NO_DEMANGLE
#include <jemalloc/jemalloc.h>

int main(void) {
#if defined(__GLIBC__) && !defined(JEMALLOC_OVERRIDE_PVALLOC)
    fprintf(stderr, "glibc has pvalloc, but jemalloc.h does not define JEMALLOC_OVERRIDE_PVALLOC\n");
    return 1;
#endif
#ifdef JEMALLOC_OVERRIDE_PVALLOC
    uint64_t before, after;
    size_t sz = sizeof(uint64_t);

    if (je_mallctl("thread.allocated", &before, &sz, NULL, 0) != 0) {
        fprintf(stderr, "Error: je_mallctl 'thread.allocated' failed\n");
        return 1;
    }
    // The volatile store keeps the compiler from eliding the pvalloc/free pair
    void * volatile p = pvalloc(4096);
    if (p == NULL) {
        fprintf(stderr, "pvalloc(4096) failed\n");
        return 1;
    }
    int ret = je_mallctl("thread.allocated", &after, &sz, NULL, 0);
    free(p);
    if (ret != 0) {
        fprintf(stderr, "Error: je_mallctl 'thread.allocated' failed\n");
        return 1;
    }

    if (after - before < 4096) {
        fprintf(stderr, "pvalloc(4096) did not allocate from jemalloc\n");
        return 1;
    }
#endif
    return 0;
}
