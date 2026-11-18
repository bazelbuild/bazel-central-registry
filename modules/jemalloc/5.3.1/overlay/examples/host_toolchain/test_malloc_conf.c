/*
 * A program's own malloc_conf overrides the library's under any prefix. JEMALLOC_NO_DEMANGLE maps je_malloc_conf and
 * je_mallctl to the configured prefix's names. This reads opt.narenas, which the definition below sets to 3. On Windows
 * the library's definition is not weak, so this links only where the library's is a common symbol.
 */
#include <stdio.h>
#define JEMALLOC_NO_DEMANGLE
#include <jemalloc/jemalloc.h>

const char *je_malloc_conf = "narenas:3";

int main(void) {
    unsigned narenas;
    size_t sz = sizeof(narenas);
    if (je_mallctl("opt.narenas", &narenas, &sz, NULL, 0) != 0 || narenas != 3) {
        fprintf(stderr, "opt.narenas is not 3, so the program's malloc_conf was not read\n");
        return 1;
    }
    return 0;
}
