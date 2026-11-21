#include <smpte2094_50/pchip.h>
#include <smpte2094_50/utils.h>

#ifdef UHDR_ENABLE_SMPTE2094_50
#include <ultrahdr/agtm.h>
#include <cstdint>
#include <vector>
#endif

#include <cmath>
#include <cstdio>

int main() {
    const float x[] = {0.0f, 1.0f, 2.0f};
    const float y[] = {0.0f, 1.0f, 4.0f};

    auto interpolator = smpte2094_50::PchipInterpolator::Create(x, y);
    if (!interpolator.ok() || std::abs(interpolator->Interpolate(1.0f) - 1.0f) > 0.0001f) {
        return 1;
    }

    auto copy = *interpolator;
    if (std::abs(copy.Interpolate(1.0f) - 1.0f) > 0.0001f) {
        return 1;
    }

    smpte2094_50::DynamicMetadata metadata;
    metadata.baseline_hdr_headroom_log2 = 2.0f;
    metadata.use_reference_white_tone_mapping_flag = true;
    smpte2094_50::PopulateUsingRwtm(metadata);

    auto status = smpte2094_50::PopulateImplicitParameters(metadata);
    if (!status.ok()) {
        std::fprintf(stderr, "%s\n", status.ToString().c_str());
        return 1;
    }

    auto encoded = smpte2094_50::ToSt209450(metadata);
    if (!encoded.ok() || encoded->empty()) return 1;

    auto decoded = smpte2094_50::FromSt209450(*encoded);
    if (!decoded.ok() || !smpte2094_50::IsValid(*decoded)) {
        return 1;
    }

    if (std::abs(decoded->baseline_hdr_headroom_log2 - 2.0f) > 0.0001f) {
        return 1;
    }

    if (decoded->rules.size() != metadata.rules.size()) {
        return 1;
    }

    if (smpte2094_50::FromSt209450("bad").ok()) {
        return 1;
    }
#ifdef UHDR_ENABLE_SMPTE2094_50
    std::vector<uint64_t> pixels(32 * 32, UINT64_C(0x3c003c003c003c00));
    uhdr_raw_image_t image = {};

    image.fmt = UHDR_IMG_FMT_64bppRGBAHalfFloat;
    image.cg = UHDR_CG_BT_2100;
    image.ct = UHDR_CT_LINEAR;
    image.range = UHDR_CR_FULL_RANGE;
    image.w = image.h = 32;

    image.planes[UHDR_PLANE_PACKED] = pixels.data();
    image.stride[UHDR_PLANE_PACKED] = 32;

    ultrahdr::uhdr_gainmap_metadata_ext_t gainmap_metadata;
    std::unique_ptr<ultrahdr::uhdr_raw_image_ext_t> gainmap;

    auto error = ultrahdr::generateGainMap(&image, *decoded, &gainmap_metadata, gainmap);
    if (error.error_code != UHDR_CODEC_OK || !gainmap || gainmap->w != 32 || gainmap->h != 32) {
        return 1;
    }
#endif
    return 0;
}
