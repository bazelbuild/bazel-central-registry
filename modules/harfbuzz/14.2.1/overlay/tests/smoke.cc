#include "hb.h"
#include "hb-raster.h"

int main() {
    hb_unicode_funcs_t* unicode = hb_unicode_funcs_get_default();
    hb_buffer_t* buffer = hb_buffer_create();

    hb_blob_t* blob = hb_blob_get_empty();
    hb_face_t* face = hb_face_create(blob, 0);
    hb_font_t* font = hb_font_create(face);

    hb_raster_draw_t* draw = hb_raster_draw_create_or_fail();
    if (draw == nullptr) {
        return 1;
    }
    hb_raster_draw_glyph(draw, font, 0);
    hb_raster_draw_destroy(draw);

    hb_font_destroy(font);
    hb_face_destroy(face);
    hb_blob_destroy(blob);
    hb_buffer_destroy(buffer);

    return unicode != nullptr ? 0 : 1;
}
