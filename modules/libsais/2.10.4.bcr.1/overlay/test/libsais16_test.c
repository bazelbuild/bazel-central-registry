#include <stdio.h>

#include "libsais16.h"

/* Suffixes of "banana" in lexicographic order:
   a, ana, anana, banana, na, nana */
static const int32_t kExpected[6] = {5, 3, 1, 0, 4, 2};

static int check(const char * name, const int32_t * sa, int32_t n) {
    for (int32_t i = 0; i < n; i += 1) {
        if (sa[i] != kExpected[i]) {
            fprintf(stderr, "%s: SA[%d] = %d, expected %d\n", name, i, sa[i], kExpected[i]);
            return 1;
        }
    }

    return 0;
}

int main(void) {
    const uint16_t text[6] = {'b', 'a', 'n', 'a', 'n', 'a'};
    int32_t n = 6;
    int32_t sa[6];

    if (libsais16(text, sa, n, 0, NULL) != 0) {
        fprintf(stderr, "libsais16 failed\n");
        return 1;
    }

    if (check("libsais16", sa, n) != 0) {
        return 1;
    }

#if defined(LIBSAIS_OPENMP)
    if (libsais16_omp(text, sa, n, 0, NULL, 2) != 0) {
        fprintf(stderr, "libsais16_omp failed\n");
        return 1;
    }

    if (check("libsais16_omp", sa, n) != 0) {
        return 1;
    }
#endif

    return 0;
}
