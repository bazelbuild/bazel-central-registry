/* End-to-end smoke test for the x265 encoder API.
 *
 * TestBench only compares the SIMD primitives against their C references; it
 * never opens an encoder. This test drives the public API instead, so it
 * covers the pieces that are configured per platform rather than per CPU:
 * the threading backend (pthreads vs. win32thread), the thread pool, and the
 * bitstream writer. */

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

#include "x265.h"

namespace {

const int kWidth = 64;
const int kHeight = 64;
const int kFrames = 8;

int fail(const char *what) {
    std::fprintf(stderr, "encode_smoke_test: %s\n", what);
    return 1;
}

/* A drifting gradient, so motion estimation has something to find. */
void fill_frame(std::vector<uint8_t> *y, std::vector<uint8_t> *u,
                std::vector<uint8_t> *v, int n) {
    for (int row = 0; row < kHeight; row++)
        for (int col = 0; col < kWidth; col++)
            (*y)[row * kWidth + col] = static_cast<uint8_t>(row + col + n * 3);
    for (int row = 0; row < kHeight / 2; row++)
        for (int col = 0; col < kWidth / 2; col++) {
            (*u)[row * kWidth / 2 + col] = static_cast<uint8_t>(128 + row - n);
            (*v)[row * kWidth / 2 + col] = static_cast<uint8_t>(128 + col + n);
        }
}

}  // namespace

int main() {
    x265_param param;
    x265_param_default(&param);
    if (x265_param_default_preset(&param, "ultrafast", NULL) != 0)
        return fail("x265_param_default_preset failed");

    param.sourceWidth = kWidth;
    param.sourceHeight = kHeight;
    param.internalCsp = X265_CSP_I420;
    param.fpsNum = 25;
    param.fpsDenom = 1;
    param.keyframeMax = 4;
    param.logLevel = X265_LOG_ERROR;

    x265_encoder *encoder = x265_encoder_open(&param);
    if (!encoder)
        return fail("x265_encoder_open failed");

    x265_nal *nal = NULL;
    uint32_t nal_count = 0;
    if (x265_encoder_headers(encoder, &nal, &nal_count) <= 0 || nal_count == 0) {
        x265_encoder_close(encoder);
        return fail("x265_encoder_headers produced no VPS/SPS/PPS");
    }

    std::vector<uint8_t> y(kWidth * kHeight);
    std::vector<uint8_t> u(kWidth * kHeight / 4);
    std::vector<uint8_t> v(kWidth * kHeight / 4);

    x265_picture pic;
    x265_picture_init(&param, &pic);
    /* Feed 8-bit input regardless of the depth the library was compiled for;
     * x265 up-shifts to the internal depth. x265_picture_init() defaults this
     * to the internal depth, which would mean 16 bits per sample. */
    pic.bitDepth = 8;
    pic.planes[0] = y.data();
    pic.planes[1] = u.data();
    pic.planes[2] = v.data();
    pic.stride[0] = kWidth;
    pic.stride[1] = kWidth / 2;
    pic.stride[2] = kWidth / 2;

    long long payload = 0;
    int access_units = 0;

    for (int n = 0; n < kFrames; n++) {
        fill_frame(&y, &u, &v, n);
        pic.pts = n;
        int ret = x265_encoder_encode(encoder, &nal, &nal_count, &pic, NULL);
        if (ret < 0) {
            x265_encoder_close(encoder);
            return fail("x265_encoder_encode failed");
        }
        for (uint32_t i = 0; i < nal_count; i++)
            payload += nal[i].sizeBytes;
        access_units += ret;
    }

    /* Passing a NULL picture flushes the frame queue. */
    for (;;) {
        int ret = x265_encoder_encode(encoder, &nal, &nal_count, NULL, NULL);
        if (ret < 0) {
            x265_encoder_close(encoder);
            return fail("x265_encoder_encode failed while flushing");
        }
        if (ret == 0)
            break;
        for (uint32_t i = 0; i < nal_count; i++)
            payload += nal[i].sizeBytes;
        access_units += ret;
    }

    x265_encoder_close(encoder);
    x265_cleanup();

    if (access_units != kFrames)
        return fail("encoder did not return one access unit per input frame");
    if (payload <= 0)
        return fail("encoder produced an empty bitstream");

    std::printf("encoded %d frames into %lld bytes\n", access_units, payload);
    return 0;
}
