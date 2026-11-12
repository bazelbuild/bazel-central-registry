/*
 * A prefix renames the MALLOC_CONF environment variable along with the public API, as INSTALL.md's
 * --with-jemalloc-prefix describes. This reads opt.narenas through je_mallctl, which JEMALLOC_NO_DEMANGLE maps to the
 * configured prefix, and expects the 3 that the test sets in the variable for that prefix.
 */
#include <stdio.h>
#define JEMALLOC_NO_DEMANGLE
#include <jemalloc/jemalloc.h>

int main(void) {
    unsigned narenas;
    size_t sz = sizeof(narenas);
    if (je_mallctl("opt.narenas", &narenas, &sz, NULL, 0) != 0 || narenas != 3) {
        fprintf(stderr, "opt.narenas is not 3, so the MALLOC_CONF variable for the prefix was not read\n");
        return 1;
    }
    return 0;
}
