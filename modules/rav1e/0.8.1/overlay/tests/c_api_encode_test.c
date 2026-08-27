#include <assert.h>
#include <stdint.h>
#include <string.h>

#include "rav1e.h"

int main(void) {
    uint8_t luma[64 * 64];
    uint8_t chroma[32 * 32];
    RaConfig *config;
    RaContext *context;
    RaFrame *frame;
    RaPacket *packet = NULL;
    RaEncoderStatus status;

    memset(luma, 96, sizeof(luma));
    memset(chroma, 128, sizeof(chroma));

    assert(strcmp(rav1e_version_short(), "0.8.1") == 0);
    config = rav1e_config_default();
    assert(config != NULL);
    assert(rav1e_config_parse_int(config, "width", 64) == 0);
    assert(rav1e_config_parse_int(config, "height", 64) == 0);
    assert(rav1e_config_parse_int(config, "speed", 10) == 0);
    assert(rav1e_config_parse_int(config, "threads", 1) == 0);

    context = rav1e_context_new(config);
    rav1e_config_unref(config);
    assert(context != NULL);

    frame = rav1e_frame_new(context);
    assert(frame != NULL);
    rav1e_frame_fill_plane(frame, 0, luma, sizeof(luma), 64, 1);
    rav1e_frame_fill_plane(frame, 1, chroma, sizeof(chroma), 32, 1);
    rav1e_frame_fill_plane(frame, 2, chroma, sizeof(chroma), 32, 1);
    assert(rav1e_send_frame(context, frame) == RA_ENCODER_STATUS_SUCCESS);
    rav1e_frame_unref(frame);
    assert(rav1e_send_frame(context, NULL) == RA_ENCODER_STATUS_SUCCESS);

    do {
        status = rav1e_receive_packet(context, &packet);
    } while (status == RA_ENCODER_STATUS_ENCODED);

    assert(status == RA_ENCODER_STATUS_SUCCESS);
    assert(packet != NULL);
    assert(packet->len > 0);
    assert(packet->frame_type == RA_FRAME_TYPE_KEY);
    rav1e_packet_unref(packet);
    rav1e_context_unref(context);
    return 0;
}
