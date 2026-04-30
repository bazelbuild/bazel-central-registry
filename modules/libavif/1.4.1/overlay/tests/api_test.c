#include <avif/avif.h>

#include <assert.h>
#include <string.h>

int main(void) {
    /* Version API */
    assert(avifVersion() != NULL);
    assert(strlen(avifVersion()) > 0);

    /* Result strings */
    assert(avifResultToString(AVIF_RESULT_OK) != NULL);
    assert(avifResultToString(AVIF_RESULT_OUT_OF_MEMORY) != NULL);

    /* Decoder lifecycle */
    avifDecoder *decoder = avifDecoderCreate();
    assert(decoder != NULL);
    avifDecoderDestroy(decoder);

    /* Encoder lifecycle */
    avifEncoder *encoder = avifEncoderCreate();
    assert(encoder != NULL);
    avifEncoderDestroy(encoder);

    return 0;
}
