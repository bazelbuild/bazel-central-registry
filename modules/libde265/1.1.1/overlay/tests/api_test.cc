#include <libde265/de265.h>
#include <libde265/de265-version.h>
#include "version_check.h"

#undef NDEBUG
#include <cassert>
#include <cstring>

// One 16x16 black HEVC frame, encoded by FFmpeg with libx265 and info=0.
constexpr unsigned char kBlackFrame[] = {
    0x00, 0x00, 0x00, 0x01, 0x40, 0x01, 0x0c, 0x01, 0xff, 0xff, 0x01, 0x60,
    0x00, 0x00, 0x03, 0x00, 0x90, 0x00, 0x00, 0x03, 0x00, 0x00, 0x03, 0x00,
    0x1e, 0x95, 0x98, 0x09, 0x00, 0x00, 0x00, 0x01, 0x42, 0x01, 0x01, 0x01,
    0x60, 0x00, 0x00, 0x03, 0x00, 0x90, 0x00, 0x00, 0x03, 0x00, 0x00, 0x03,
    0x00, 0x1e, 0xa0, 0x88, 0x45, 0x96, 0x56, 0x6a, 0xbc, 0xaf, 0x01, 0x68,
    0x08, 0x00, 0x00, 0x03, 0x00, 0x08, 0x00, 0x00, 0x03, 0x00, 0xc8, 0x40,
    0x00, 0x00, 0x00, 0x01, 0x44, 0x01, 0xc1, 0x73, 0xd0, 0x89, 0x00, 0x00,
    0x01, 0x28, 0x01, 0xaf, 0x1d, 0x80, 0xee, 0x23, 0x8f, 0xff, 0x5e, 0x8f,
};

int main() {
    // LIBDE265_VERSION is derived from write_file in BUILD.bazel.
    // PACKAGE_VERSION is derived from MODULE.bazel via package_info.
    // If these differ, the BUILD.bazel version is out of sync.
    assert(strcmp(LIBDE265_VERSION, PACKAGE_VERSION) == 0);
    assert(strcmp(de265_get_version(), PACKAGE_VERSION) == 0);
    assert(de265_get_version_number() == LIBDE265_NUMERIC_VERSION);

    // Error text API
    assert(de265_get_error_text(DE265_OK) != nullptr);
    assert(de265_isOK(DE265_OK));
    assert(!de265_isOK(DE265_ERROR_OUT_OF_MEMORY));

    // Decoder lifecycle
    de265_decoder_context* ctx = de265_new_decoder();
    assert(ctx != nullptr);

    // Pushing empty data should not crash
    de265_error err = de265_flush_data(ctx);
    assert(de265_isOK(err));

    // No image available without input
    const de265_image* img = de265_get_next_picture(ctx);
    assert(img == nullptr);

    de265_reset(ctx);
    assert(de265_isOK(de265_push_data(ctx, kBlackFrame, sizeof(kBlackFrame), 0, nullptr)));
    assert(de265_isOK(de265_flush_data(ctx)));
    int more = 1;
    while (more && (img = de265_peek_next_picture(ctx)) == nullptr) {
        assert(de265_decode(ctx, &more) == DE265_OK);
    }
    img = de265_peek_next_picture(ctx);
    assert(img != nullptr);
    for (int channel = 0; channel < 3; ++channel) {
        const int size = channel == 0 ? 16 : 8;
        const int pixel = channel == 0 ? 16 : 128;
        assert(de265_get_image_width(img, channel) == size);
        assert(de265_get_image_height(img, channel) == size);
        int stride;
        const uint8_t* plane = de265_get_image_plane(img, channel, &stride);
        assert(plane != nullptr);
        for (int y = 0; y < size; ++y) {
            for (int x = 0; x < size; ++x) {
                assert(plane[y * stride + x] == pixel);
            }
        }
    }
    de265_release_next_picture(ctx);

    err = de265_free_decoder(ctx);
    assert(de265_isOK(err));

    return 0;
}
