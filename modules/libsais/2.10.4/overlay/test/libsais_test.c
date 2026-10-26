#include <stdio.h>
#include <string.h>

#include "libsais.h"

/* Suffixes of "banana" in lexicographic order:
   a, ana, anana, banana, na, nana */
static const int32_t kExpected[6] = {5, 3, 1, 0, 4, 2};

int main(void) {
    const char * text = "banana";
    int32_t n = (int32_t)strlen(text);
    int32_t sa[6];

    if (libsais((const uint8_t *)text, sa, n, 0, NULL) != 0) {
        fprintf(stderr, "libsais failed\n");
        return 1;
    }

    for (int32_t i = 0; i < n; i += 1) {
        if (sa[i] != kExpected[i]) {
            fprintf(stderr, "SA[%d] = %d, expected %d\n", i, sa[i], kExpected[i]);
            return 1;
        }
    }

    return 0;
}
