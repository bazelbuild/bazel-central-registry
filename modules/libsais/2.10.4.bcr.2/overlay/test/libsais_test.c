#include <stdio.h>
#include <string.h>

#include "libsais.h"

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
    const char * text = "banana";
    int32_t n = (int32_t)strlen(text);
    int32_t sa[6];

    if (libsais((const uint8_t *)text, sa, n, 0, NULL) != 0) {
        fprintf(stderr, "libsais failed\n");
        return 1;
    }

    if (check("libsais", sa, n) != 0) {
        return 1;
    }

#if defined(LIBSAIS_OPENMP)
    if (libsais_omp((const uint8_t *)text, sa, n, 0, NULL, 2) != 0) {
        fprintf(stderr, "libsais_omp failed\n");
        return 1;
    }

    if (check("libsais_omp", sa, n) != 0) {
        return 1;
    }
#endif

    return 0;
}
