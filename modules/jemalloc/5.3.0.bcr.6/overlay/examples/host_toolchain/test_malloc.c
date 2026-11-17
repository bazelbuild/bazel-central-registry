/*
 * Under the platform's default prefix, plain malloc must reach jemalloc: through the replaced symbols when there is no
 * prefix, and through the default malloc zone on macOS, where the prefix is je_. thread.allocated counts the bytes this
 * thread allocates through jemalloc. The manual marks it [--enable-stats], but in this version thread events keep the
 * counter and src/ctl.c does not gate it on stats, so the check also runs without stats.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#define JEMALLOC_NO_DEMANGLE
#include <jemalloc/jemalloc.h>

#ifdef __APPLE__
#include <malloc/malloc.h>
#include <string.h>

/*
 * On macOS plain malloc reaches jemalloc only through jemalloc_zone, so that zone must own the pointer. The pointer's
 * zone cannot show this: on macOS 15.1, malloc_zone_from_ptr() was observed to report the virtual default zone for
 * pointers the first registered zone owns, the zone malloc_default_zone() has returned since OS X 10.12 (see
 * src/zone.c's zone_default_get()). jemalloc_zone's size() returns 0 for a pointer it does not own.
 */
static int owned_by_jemalloc_zone(const void *p) {
    vm_address_t *zones = NULL;
    unsigned int num_zones = 0;
    if (malloc_get_all_zones(0, NULL, &zones, &num_zones) != KERN_SUCCESS) {
        return 0;
    }
    for (unsigned int i = 0; i < num_zones; i++) {
        malloc_zone_t *zone = (malloc_zone_t *)zones[i];
        const char *name = malloc_get_zone_name(zone);
        if (name != NULL && strcmp(name, "jemalloc_zone") == 0) {
            return zone->size(zone, p) > 0;
        }
    }
    return 0;
}
#endif

int main(void) {
    uint64_t before, after;
    size_t sz = sizeof(uint64_t);

    if (je_mallctl("thread.allocated", &before, &sz, NULL, 0) != 0) {
        fprintf(stderr, "Error: je_mallctl 'thread.allocated' failed\n");
        return 1;
    }
    // The volatile store keeps the compiler from eliding the malloc/free pair
    void * volatile p = malloc(4096);
    if (p == NULL) {
        fprintf(stderr, "malloc(4096) failed\n");
        return 1;
    }
    int ret = je_mallctl("thread.allocated", &after, &sz, NULL, 0);
#ifdef __APPLE__
    int owned = owned_by_jemalloc_zone(p);
#endif
    free(p);
    if (ret != 0) {
        fprintf(stderr, "Error: je_mallctl 'thread.allocated' failed\n");
        return 1;
    }

    if (after - before < 4096) {
        fprintf(stderr, "malloc(4096) did not allocate from jemalloc\n");
        return 1;
    }
#ifdef __APPLE__
    if (!owned) {
        fprintf(stderr, "jemalloc_zone does not own the memory malloc(4096) returned\n");
        return 1;
    }
#endif
    return 0;
}
