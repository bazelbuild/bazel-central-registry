#include <stdio.h>

#include "vpx/vp8dx.h"
#include "vpx/vpx_codec.h"

int main(void) {
    const vpx_codec_iface_t *iface = vpx_codec_vp8_dx();
    if (iface == NULL) {
        return 1;
    }

    puts(vpx_codec_iface_name(iface));
    puts(vpx_codec_version_str());
    return 0;
}
