#include <stdint.h>
#include <stdio.h>

#include "skcms.h"

int main(void) {
    /* 65 pixels exercise complete SIMD batches and a final partial batch. */
    enum { kPixelCount = 65, kComponentCount = 4 * kPixelCount };
    float input[kComponentCount];
    uint8_t encoded[kComponentCount] = {0};
    float decoded[kComponentCount] = {0};

    for (int i = 0; i < kComponentCount; i++) {
        input[i] = (uint8_t)i / 255.0f;
    }
    input[0] = -0.25f;
    input[64] = 0.25f;
    input[128] = 0.5f;
    input[191] = 0.75f;
    input[255] = 1.25f;

    if (!skcms_Transform(input, skcms_PixelFormat_RGBA_ffff,
                         skcms_AlphaFormat_Unpremul, NULL,
                         encoded, skcms_PixelFormat_RGBA_8888,
                         skcms_AlphaFormat_Unpremul, NULL, kPixelCount)) {
        fprintf(stderr, "float RGBA to 8-bit RGBA conversion failed\n");
        return 1;
    }
    for (int i = 0; i < kComponentCount; i++) {
        const uint8_t expected = (uint8_t)i;
        if (encoded[i] != expected) {
            fprintf(stderr, "component %d: expected byte %u, got %u\n",
                    i, (unsigned)expected, (unsigned)encoded[i]);
            return 1;
        }
    }

    if (!skcms_Transform(encoded, skcms_PixelFormat_RGBA_8888,
                         skcms_AlphaFormat_Unpremul, NULL,
                         decoded, skcms_PixelFormat_RGBA_ffff,
                         skcms_AlphaFormat_Unpremul, NULL, kPixelCount)) {
        fprintf(stderr, "8-bit RGBA to float RGBA conversion failed\n");
        return 1;
    }
    for (int i = 0; i < kComponentCount; i++) {
        const float expected = (uint8_t)i / 255.0f;
        const float difference = decoded[i] - expected;
        if (!(difference >= -0.000001f && difference <= 0.000001f)) {
            fprintf(stderr, "component %d: expected float %.9g, got %.9g\n",
                    i, (double)expected, (double)decoded[i]);
            return 1;
        }
    }
    return 0;
}
