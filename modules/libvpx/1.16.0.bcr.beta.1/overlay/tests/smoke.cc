// Runnable smoke test for the consumer-facing libvpx API.
//
// This test builds a tiny synthetic I420 frame in memory, encodes it as
// lossless VP9, decodes the compressed payload back, and checks that the
// decoded Y/U/V planes match the original exactly.

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <utility>

#include "vpx/vp8cx.h"
#include "vpx/vp8dx.h"
#include "vpx/vpx_decoder.h"
#include "vpx/vpx_encoder.h"
#include "vpx/vpx_image.h"

namespace {

constexpr unsigned int kWidth = 16;
constexpr unsigned int kHeight = 16;
constexpr std::size_t kMaxEncodedBytes = 64 * 1024;

using ByteBuffer = std::array<std::uint8_t, kMaxEncodedBytes>;

template <typename F>
class Cleanup {
public:
    explicit Cleanup(F&& callback) : callback_(std::move(callback)), engaged_(true) {}

    Cleanup(const Cleanup&) = delete;
    Cleanup& operator=(const Cleanup&) = delete;

    Cleanup(Cleanup&& other)
        : callback_(std::move(other.callback_)), engaged_(other.engaged_) {
        other.engaged_ = false;
    }

    ~Cleanup() {
        if (engaged_) {
            callback_();
        }
    }

    void Cancel() { engaged_ = false; }

private:
    F callback_;
    bool engaged_;
};

template <typename F>
Cleanup<F> MakeCleanup(F&& callback) {
    return Cleanup<F>(std::forward<F>(callback));
}

int Fail(const char* message) {
    std::fprintf(stderr, "smoke: %s\n", message);
    return 1;
}

int FillTestImage(vpx_image_t* image) {
    if (image == nullptr || image->fmt != VPX_IMG_FMT_I420) {
        return Fail("unexpected source image format");
    }

    for (unsigned int y = 0; y < kHeight; ++y) {
        std::uint8_t* row = image->planes[VPX_PLANE_Y] + y * image->stride[VPX_PLANE_Y];
        for (unsigned int x = 0; x < kWidth; ++x) {
            const bool top = y < (kHeight / 2);
            const bool left = x < (kWidth / 2);
            row[x] = top ? (left ? 32 : 96) : (left ? 160 : 224);
        }
    }

    for (unsigned int y = 0; y < kHeight / 2; ++y) {
        std::uint8_t* u_row = image->planes[VPX_PLANE_U] + y * image->stride[VPX_PLANE_U];
        std::uint8_t* v_row = image->planes[VPX_PLANE_V] + y * image->stride[VPX_PLANE_V];
        for (unsigned int x = 0; x < kWidth / 2; ++x) {
            const bool top = y < (kHeight / 4);
            const bool left = x < (kWidth / 4);
            if (top && left) {
                u_row[x] = 96;
                v_row[x] = 160;
            } else if (top) {
                u_row[x] = 112;
                v_row[x] = 176;
            } else if (left) {
                u_row[x] = 128;
                v_row[x] = 192;
            } else {
                u_row[x] = 144;
                v_row[x] = 208;
            }
        }
    }

    return 0;
}

bool PlaneEquals(
    const char* plane_name,
    const std::uint8_t* lhs,
    int lhs_stride,
    const std::uint8_t* rhs,
    int rhs_stride,
    unsigned int width,
    unsigned int height) {
    for (unsigned int y = 0; y < height; ++y) {
        if (std::memcmp(lhs + y * lhs_stride, rhs + y * rhs_stride, width) != 0) {
            std::fprintf(stderr, "smoke: %s plane mismatch on row %u\n", plane_name, y);
            return false;
        }
    }
    return true;
}

int EncodeFrame(
    vpx_image_t* image,
    ByteBuffer* encoded_bytes,
    std::size_t* encoded_size) {
    if (image == nullptr || encoded_bytes == nullptr || encoded_size == nullptr) {
        return Fail("invalid encode inputs");
    }

    vpx_codec_enc_cfg_t config;
    if (vpx_codec_enc_config_default(vpx_codec_vp9_cx(), &config, 0) != VPX_CODEC_OK) {
        return Fail("failed to get encoder default config");
    }

    config.g_w = kWidth;
    config.g_h = kHeight;
    config.g_timebase.num = 1;
    config.g_timebase.den = 1;
    config.g_lag_in_frames = 0;
    config.rc_end_usage = VPX_Q;
    config.g_threads = 1;

    vpx_codec_ctx_t encoder;
    std::memset(&encoder, 0, sizeof(encoder));
    if (vpx_codec_enc_init(&encoder, vpx_codec_vp9_cx(), &config, 0) != VPX_CODEC_OK) {
        return Fail("failed to initialize encoder");
    }
    const auto destroy_encoder = MakeCleanup([&encoder]() { vpx_codec_destroy(&encoder); });

    int status = 1;
    *encoded_size = 0;

    const auto collect_packets = [&]() -> bool {
        vpx_codec_iter_t iter = nullptr;
        const vpx_codec_cx_pkt_t* packet = nullptr;
        while ((packet = vpx_codec_get_cx_data(&encoder, &iter)) != nullptr) {
            if (packet->kind != VPX_CODEC_CX_FRAME_PKT) {
                continue;
            }

            const std::size_t packet_size = packet->data.frame.sz;
            if (*encoded_size + packet_size > encoded_bytes->size()) {
                status = Fail("encoded frame exceeded fixed buffer");
                return false;
            }

            std::memcpy(
                encoded_bytes->data() + *encoded_size,
                packet->data.frame.buf,
                packet_size);
            *encoded_size += packet_size;
        }

        return true;
    };

    if (vpx_codec_control(&encoder, VP9E_SET_LOSSLESS, 1) == VPX_CODEC_OK &&
        vpx_codec_encode(&encoder, image, 0, 1, 0, VPX_DL_GOOD_QUALITY) == VPX_CODEC_OK &&
        collect_packets() &&
        vpx_codec_encode(&encoder, nullptr, 1, 1, 0, VPX_DL_GOOD_QUALITY) == VPX_CODEC_OK &&
        collect_packets()) {
        if (*encoded_size != 0) {
            status = 0;
        } else {
            status = Fail("encoder produced no frame packets");
        }
    } else if (status == 1) {
        status = Fail("encode pipeline failed");
    }

    return status;
}

int DecodeAndVerify(const vpx_image_t* expected, const ByteBuffer& encoded_bytes, std::size_t encoded_size) {
    if (expected == nullptr || encoded_size == 0) {
        return Fail("invalid decode inputs");
    }

    vpx_codec_ctx_t decoder;
    std::memset(&decoder, 0, sizeof(decoder));
    if (vpx_codec_dec_init(&decoder, vpx_codec_vp9_dx(), nullptr, 0) != VPX_CODEC_OK) {
        return Fail("failed to initialize decoder");
    }
    const auto destroy_decoder = MakeCleanup([&decoder]() { vpx_codec_destroy(&decoder); });

    int status = 1;
    vpx_codec_iter_t iter = nullptr;
    const vpx_image_t* decoded = nullptr;

    if (vpx_codec_decode(
            &decoder,
            encoded_bytes.data(),
            static_cast<unsigned int>(encoded_size),
            nullptr,
            0) == VPX_CODEC_OK) {
        decoded = vpx_codec_get_frame(&decoder, &iter);
        if (decoded == nullptr) {
            status = Fail("decoder produced no frames");
        } else if (vpx_codec_get_frame(&decoder, &iter) != nullptr) {
            status = Fail("decoder produced more than one frame");
        } else if (decoded->fmt != VPX_IMG_FMT_I420) {
            status = Fail("decoded frame format mismatch");
        } else if (decoded->d_w != kWidth || decoded->d_h != kHeight) {
            status = Fail("decoded frame dimensions mismatch");
        } else if (!PlaneEquals(
                       "Y",
                       expected->planes[VPX_PLANE_Y], expected->stride[VPX_PLANE_Y],
                       decoded->planes[VPX_PLANE_Y], decoded->stride[VPX_PLANE_Y],
                       kWidth, kHeight)) {
            status = 1;
        } else if (!PlaneEquals(
                       "U",
                       expected->planes[VPX_PLANE_U], expected->stride[VPX_PLANE_U],
                       decoded->planes[VPX_PLANE_U], decoded->stride[VPX_PLANE_U],
                       kWidth / 2, kHeight / 2)) {
            status = 1;
        } else if (!PlaneEquals(
                       "V",
                       expected->planes[VPX_PLANE_V], expected->stride[VPX_PLANE_V],
                       decoded->planes[VPX_PLANE_V], decoded->stride[VPX_PLANE_V],
                       kWidth / 2, kHeight / 2)) {
            status = 1;
        } else {
            status = 0;
        }
    } else {
        status = Fail("decode call failed");
    }

    return status;
}

}  // namespace

int main() {
    if (vpx_codec_vp9_dx() == nullptr || vpx_codec_vp9_cx() == nullptr) {
        return Fail("VP9 codec interfaces are unavailable");
    }

    vpx_image_t image;
    std::memset(&image, 0, sizeof(image));
    if (vpx_img_alloc(&image, VPX_IMG_FMT_I420, kWidth, kHeight, 1) == nullptr) {
        return Fail("failed to allocate source image");
    }
    const auto free_image = MakeCleanup([&image]() { vpx_img_free(&image); });

    ByteBuffer encoded_bytes = {};
    std::size_t encoded_size = 0;
    const int status = (FillTestImage(&image) == 0 &&
                        EncodeFrame(&image, &encoded_bytes, &encoded_size) == 0 &&
                        DecodeAndVerify(&image, encoded_bytes, encoded_size) == 0)
                           ? 0
                           : 1;
    return status;
}
