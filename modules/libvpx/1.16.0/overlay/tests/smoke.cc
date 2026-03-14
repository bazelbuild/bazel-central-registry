#include "vpx/vp8cx.h"
#include "vpx/vp8dx.h"
#include "vpx/vpx_decoder.h"
#include "vpx/vpx_encoder.h"

int main() {
    return (vpx_codec_vp9_dx() != nullptr && vpx_codec_vp9_cx() != nullptr) ? 0 : 1;
}
