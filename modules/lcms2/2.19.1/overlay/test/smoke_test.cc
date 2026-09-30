// A downstream consumer of the @lcms2 module. The bare #include "lcms2.h"
// spelling is the strip_include_prefix contract under test. The version check
// mirrors the first assertion of upstream's own testbed harness:
// cmsGetEncodedCMMversion() coming back different from the header's
// LCMS_VERSION means the module wired a header from one release against
// object code from another. Everything stays in memory on purpose: this test
// runs on the full BCR matrix including Windows, where CWD-relative file I/O
// against a materialized runfiles tree is not guaranteed.

#include <stdio.h>

#include "lcms2.h"

int main(void) {
    if (cmsGetEncodedCMMversion() != LCMS_VERSION) {
        fprintf(stderr, "FAIL: header LCMS_VERSION is %d but the library reports %d\n",
                LCMS_VERSION, cmsGetEncodedCMMversion());
        return 1;
    }

    cmsHPROFILE srgb = cmsCreate_sRGBProfile();
    cmsHPROFILE lab = cmsCreateLab4Profile(NULL);
    if (srgb == NULL || lab == NULL) {
        fprintf(stderr, "FAIL: could not create sRGB/Lab profiles in memory\n");
        return 1;
    }

    cmsHTRANSFORM to_lab =
        cmsCreateTransform(srgb, TYPE_RGB_8, lab, TYPE_Lab_DBL, INTENT_RELATIVE_COLORIMETRIC, 0);
    cmsHTRANSFORM to_rgb =
        cmsCreateTransform(lab, TYPE_Lab_DBL, srgb, TYPE_RGB_8, INTENT_RELATIVE_COLORIMETRIC, 0);
    if (to_lab == NULL || to_rgb == NULL) {
        fprintf(stderr, "FAIL: could not build sRGB<->Lab transforms\n");
        return 1;
    }

    const unsigned char rgb_in[3] = {200, 100, 50};
    cmsCIELab lab_val;
    unsigned char rgb_out[3] = {0, 0, 0};
    cmsDoTransform(to_lab, rgb_in, &lab_val, 1);
    cmsDoTransform(to_rgb, &lab_val, rgb_out, 1);

    if (!(lab_val.L > 0.0 && lab_val.L < 100.0 && lab_val.a > 0.0 && lab_val.b > 0.0)) {
        fprintf(stderr, "FAIL: Lab for an orange sRGB value is implausible: L=%f a=%f b=%f\n",
                lab_val.L, lab_val.a, lab_val.b);
        return 1;
    }

    int max_diff = 0;
    for (int i = 0; i < 3; i++) {
        int d = (int)rgb_in[i] - (int)rgb_out[i];
        if (d < 0) {
            d = -d;
        }
        if (d > max_diff) {
            max_diff = d;
        }
    }
    // An in-gamut 8-bit value through Lab doubles and back loses at most
    // quantization error; a channel drifting by more than 2/255 means the
    // transform math is broken, not merely rounded.
    if (max_diff > 2) {
        fprintf(stderr, "FAIL: sRGB->Lab->sRGB roundtrip drifted by %d: (%d,%d,%d) -> (%d,%d,%d)\n",
                max_diff, rgb_in[0], rgb_in[1], rgb_in[2], rgb_out[0], rgb_out[1], rgb_out[2]);
        return 1;
    }

    cmsDeleteTransform(to_lab);
    cmsDeleteTransform(to_rgb);
    cmsCloseProfile(srgb);
    cmsCloseProfile(lab);
    return 0;
}
