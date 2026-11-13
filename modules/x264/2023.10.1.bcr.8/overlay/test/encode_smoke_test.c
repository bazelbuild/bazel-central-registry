/* End-to-end smoke test for the x264 encoder API.
 *
 * checkasm only compares the SIMD/assembly kernels against their C references,
 * and it cannot be built with MSVC. This test drives the public API instead,
 * so it covers the pieces that are configured per platform rather than per
 * CPU: the threading backend (pthreads vs. win32thread), the lookahead thread
 * pool, and the bitstream writer. */

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "x264.h"

#define WIDTH 64
#define HEIGHT 64
#define FRAMES 8

static int fail(const char *what) {
    fprintf(stderr, "encode_smoke_test: %s\n", what);
    return 1;
}

/* A drifting gradient, so motion estimation has something to find. */
static void fill_frame(x264_picture_t *pic, int n) {
    int row, col;

    for (row = 0; row < HEIGHT; row++)
        for (col = 0; col < WIDTH; col++)
            pic->img.plane[0][row * pic->img.i_stride[0] + col] =
                (uint8_t)(row + col + n * 3);
    for (row = 0; row < HEIGHT / 2; row++)
        for (col = 0; col < WIDTH / 2; col++) {
            pic->img.plane[1][row * pic->img.i_stride[1] + col] =
                (uint8_t)(128 + row - n);
            pic->img.plane[2][row * pic->img.i_stride[2] + col] =
                (uint8_t)(128 + col + n);
        }
}

int main(void) {
    x264_param_t param;
    x264_picture_t pic_in, pic_out;
    x264_t *encoder;
    x264_nal_t *nal;
    long long payload = 0;
    int access_units = 0;
    int nal_count, size, n;

    if (x264_param_default_preset(&param, "ultrafast", NULL) < 0)
        return fail("x264_param_default_preset failed");

    param.i_csp = X264_CSP_I420;
    param.i_bitdepth = 8;
    param.i_width = WIDTH;
    param.i_height = HEIGHT;
    param.i_fps_num = 25;
    param.i_fps_den = 1;
    param.i_keyint_max = 4;
    param.i_log_level = X264_LOG_ERROR;

    if (x264_param_apply_profile(&param, "high") < 0)
        return fail("x264_param_apply_profile failed");

    if (x264_picture_alloc(&pic_in, param.i_csp, param.i_width, param.i_height) < 0)
        return fail("x264_picture_alloc failed");

    encoder = x264_encoder_open(&param);
    if (!encoder) {
        x264_picture_clean(&pic_in);
        return fail("x264_encoder_open failed");
    }

    if (x264_encoder_headers(encoder, &nal, &nal_count) <= 0 || nal_count == 0) {
        x264_encoder_close(encoder);
        x264_picture_clean(&pic_in);
        return fail("x264_encoder_headers produced no SPS/PPS");
    }

    for (n = 0; n < FRAMES; n++) {
        fill_frame(&pic_in, n);
        pic_in.i_pts = n;
        size = x264_encoder_encode(encoder, &nal, &nal_count, &pic_in, &pic_out);
        if (size < 0) {
            x264_encoder_close(encoder);
            x264_picture_clean(&pic_in);
            return fail("x264_encoder_encode failed");
        }
        if (size > 0) {
            payload += size;
            access_units++;
        }
    }

    /* Drain the frames still held by the lookahead and the B-frame delay. */
    while (x264_encoder_delayed_frames(encoder)) {
        size = x264_encoder_encode(encoder, &nal, &nal_count, NULL, &pic_out);
        if (size < 0) {
            x264_encoder_close(encoder);
            x264_picture_clean(&pic_in);
            return fail("x264_encoder_encode failed while flushing");
        }
        if (size > 0) {
            payload += size;
            access_units++;
        }
    }

    x264_encoder_close(encoder);
    x264_picture_clean(&pic_in);

    if (access_units != FRAMES)
        return fail("encoder did not return one access unit per input frame");
    if (payload <= 0)
        return fail("encoder produced an empty bitstream");

    printf("encoded %d frames into %lld bytes\n", access_units, payload);
    return 0;
}
