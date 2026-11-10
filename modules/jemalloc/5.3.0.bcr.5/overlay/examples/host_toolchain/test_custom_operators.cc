/*
 * An application that defines its own replaceable global operator new and delete, delegating storage to malloc, must
 * still link against jemalloc and keep its operators. On macOS malloc then reaches jemalloc through jemalloc_zone, so
 * the memory operator new returns is owned by that zone. jemalloc_zone's size() returns 0 for a pointer it does not
 * own; the pointer's zone cannot show this, as malloc_zone_from_ptr() reports a virtual default zone.
 *
 * The application must define every overload its code calls. An overload it leaves out is resolved from
 * jemalloc_cpp.o, which also defines the ones it replaced, and the link fails on duplicate symbols. So this defines the
 * sized operator delete too: compilers that enable sized deallocation by default emit a call to it for delete p.
 */
#include <malloc/malloc.h>

#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <new>

static std::size_t operator_new_bytes = 0;

void *operator new(std::size_t size) {
    operator_new_bytes += size;
    if (void *p = std::malloc(size)) {
        return p;
    }
    throw std::bad_alloc();
}

void operator delete(void *p) noexcept { std::free(p); }

void operator delete(void *p, std::size_t) noexcept { std::free(p); }

static bool owned_by_jemalloc_zone(const void *p) {
    vm_address_t *zones = nullptr;
    unsigned int num_zones = 0;
    if (malloc_get_all_zones(0, nullptr, &zones, &num_zones) != KERN_SUCCESS) {
        return false;
    }
    for (unsigned int i = 0; i < num_zones; i++) {
        malloc_zone_t *zone = reinterpret_cast<malloc_zone_t *>(zones[i]);
        const char *name = malloc_get_zone_name(zone);
        if (name != nullptr && std::strcmp(name, "jemalloc_zone") == 0) {
            return zone->size(zone, p) > 0;
        }
    }
    return false;
}

int main() {
    int *volatile p = new int(7);
    bool owned = owned_by_jemalloc_zone(p);
    delete p;

    if (operator_new_bytes < sizeof(int)) {
        std::fprintf(stderr, "the application's operator new was not called\n");
        return 1;
    }
    if (!owned) {
        std::fprintf(stderr, "jemalloc_zone does not own the memory the application's operator new returned\n");
        return 1;
    }
    return 0;
}
