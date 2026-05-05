#include <stdlib.h>
#include <string.h>

#include <lzo/lzo1x.h>

#define INPUT_LEN 4096u
#define OUTPUT_LEN (INPUT_LEN + INPUT_LEN / 16u + 64u + 3u)

int main(void) {
    unsigned char input[INPUT_LEN];
    unsigned char compressed[OUTPUT_LEN];
    unsigned char restored[INPUT_LEN];
    lzo_uint compressed_len = OUTPUT_LEN;
    lzo_uint restored_len = INPUT_LEN;
    lzo_voidp workmem = malloc(LZO1X_1_MEM_COMPRESS);

    if (workmem == NULL) {
        return 1;
    }

    for (size_t i = 0; i < INPUT_LEN; ++i) {
        input[i] = (unsigned char)(i % 251u);
    }

    if (lzo_init() != LZO_E_OK) {
        free(workmem);
        return 1;
    }

    if (lzo1x_1_compress(input, INPUT_LEN, compressed, &compressed_len, workmem) != LZO_E_OK) {
        free(workmem);
        return 1;
    }

    if (lzo1x_decompress_safe(compressed, compressed_len, restored, &restored_len, NULL) != LZO_E_OK) {
        free(workmem);
        return 1;
    }

    free(workmem);
    return restored_len == INPUT_LEN && memcmp(input, restored, INPUT_LEN) == 0 ? 0 : 1;
}
