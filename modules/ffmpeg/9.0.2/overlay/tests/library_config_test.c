#include "config.h"
#include "config_components.h"
#include "libavdevice/avdevice.h"
#include "libavformat/avformat.h"

#if CONFIG_LIBVPX != EXPECT_LIBVPX
#error CONFIG_LIBVPX must match the libavcodec dependency
#endif

#if CONFIG_LIBXCB != EXPECT_LIBXCB || \
    CONFIG_LIBXCB_SHAPE != EXPECT_LIBXCB || \
    CONFIG_LIBXCB_SHM != EXPECT_LIBXCB || \
    CONFIG_LIBXCB_XFIXES != EXPECT_LIBXCB
#error XCB configuration must match the libavdevice dependency
#endif

int main(void) {
    avdevice_register_all();
#if CONFIG_LIBXCB
    if (!av_find_input_format("x11grab"))
        return 1;
#endif
#if CONFIG_WEBM_MUXER
    /* Link the selected muxer without relying on an ISO muxer being enabled. */
    if (!av_guess_format("webm", NULL, NULL))
        return 1;
#endif
    return 0;
}
