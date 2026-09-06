#include <stdio.h>
#include <string.h>

#include "libsais64.h"

/* Suffixes of "banana" in lexicographic order:
   a, ana, anana, banana, na, nana */
static const int64_t kExpected[6] = {5, 3, 1, 0, 4, 2};

static int check(const char * name, const int64_t * sa, int64_t n) {
    for (int64_t i = 0; i < n; i += 1) {
        if (sa[i] != kExpected[i]) {
            fprintf(stderr, "%s: SA[%lld] = %lld, expected %lld\n", name, (long long)i, (long long)sa[i], (long long)kExpected[i]);
            return 1;
        }
    }

    return 0;
}

int main(void) {
    const char * text = "banana";
    int64_t n = (int64_t)strlen(text);
    int64_t sa[6];

    if (libsais64((const uint8_t *)text, sa, n, 0, NULL) != 0) {
        fprintf(stderr, "libsais64 failed\n");
        return 1;
    }

    if (check("libsais64", sa, n) != 0) {
        return 1;
    }

#if defined(LIBSAIS_OPENMP)
    if (libsais64_omp((const uint8_t *)text, sa, n, 0, NULL, 2) != 0) {
        fprintf(stderr, "libsais64_omp failed\n");
        return 1;
    }

    if (check("libsais64_omp", sa, n) != 0) {
        return 1;
    }
#endif

    return 0;
}
