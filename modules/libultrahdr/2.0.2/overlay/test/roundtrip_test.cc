#include <ultrahdr_api.h>

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <vector>

static bool check(uhdr_error_info_t error) {
    if (error.error_code == UHDR_CODEC_OK) return true;
    std::fprintf(stderr, "Ultra HDR error %d: %s\n", error.error_code, error.detail);
    return false;
}

int main(int argc, char** argv) {
    uhdr_codec_t format = UHDR_CODEC_JPG;

    if (argc > 1) {
        if (std::strcmp(argv[1], "heif") == 0) format = UHDR_CODEC_HEIF;
        else if (std::strcmp(argv[1], "avif") == 0) format = UHDR_CODEC_AVIF;
        else return 1;
    }

    const unsigned int width = 32;
    const unsigned int height = 32;
    std::vector<uint64_t> pixels(width * height, UINT64_C(0x3c003c003c003c00));

    uhdr_raw_image_t image = {};
    image.fmt = UHDR_IMG_FMT_64bppRGBAHalfFloat;
    image.cg = UHDR_CG_BT_2100;
    image.ct = UHDR_CT_LINEAR;
    image.range = UHDR_CR_FULL_RANGE;
    image.w = width;
    image.h = height;
    image.planes[UHDR_PLANE_PACKED] = pixels.data();
    image.stride[UHDR_PLANE_PACKED] = width;

    uhdr_codec_private_t* encoder = uhdr_create_encoder();
    uhdr_codec_private_t* decoder = uhdr_create_decoder();
    if (!encoder || !decoder) {
        uhdr_release_encoder(encoder);
        uhdr_release_decoder(decoder);
        return 1;
    }

    bool ok = check(uhdr_enc_set_output_format(encoder, format)) &&
              check(uhdr_enc_set_preset(encoder, UHDR_USAGE_REALTIME)) &&
              check(uhdr_enc_set_raw_image(encoder, &image, UHDR_HDR_IMG)) &&
              check(uhdr_encode(encoder));

    uhdr_compressed_image_t* stream = ok ? uhdr_get_encoded_stream(encoder) : nullptr;
    ok = ok && stream && stream->data_sz > 0 &&
         is_uhdr_image(stream->data, static_cast<int>(stream->data_sz)) == 1 &&
         check(uhdr_dec_set_image(decoder, stream)) &&
         check(uhdr_dec_probe(decoder)) &&
         uhdr_dec_get_image_width(decoder) == static_cast<int>(width) &&
         uhdr_dec_get_image_height(decoder) == static_cast<int>(height) &&
         check(uhdr_decode(decoder));

    uhdr_raw_image_t* decoded = ok ? uhdr_get_decoded_image(decoder) : nullptr;
    ok = ok && decoded && decoded->w == width && decoded->h == height &&
         decoded->planes[UHDR_PLANE_PACKED];

    uhdr_release_decoder(decoder);
    uhdr_release_encoder(encoder);

    return ok ? 0 : 1;
}
