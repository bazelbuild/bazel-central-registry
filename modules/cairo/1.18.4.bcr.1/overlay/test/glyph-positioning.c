#include <cairo.h>
#include <stdio.h>

#define CHECK(condition) do { if (!(condition)) { \
    fprintf(stderr, "Failed: %s at line %d\n", #condition, __LINE__); \
    return 1; } } while (0)

/* A one-em square gives a geometric reference without any font files. */
static cairo_status_t square_glyph(cairo_scaled_font_t *font,
                                  unsigned long glyph,
                                  cairo_t *cr,
                                  cairo_text_extents_t *extents) {
    (void)font;
    (void)glyph;
    cairo_rectangle(cr, 0, -1, 1, 1);
    cairo_fill(cr);
    /* Leave padding around the square for fractional antialiasing coverage. */
    extents->x_bearing = -0.5;
    extents->y_bearing = -1.5;
    extents->width = 2;
    extents->height = 2;
    extents->x_advance = 1;
    extents->y_advance = 0;
    return cairo_status(cr);
}

static cairo_surface_t *render(cairo_font_face_t *face, double x, double y,
                               int as_glyph) {
    cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_A8, 64, 64);
    cairo_t *cr = cairo_create(surface);
    cairo_set_antialias(cr, CAIRO_ANTIALIAS_GRAY);
    if (as_glyph) {
        cairo_font_options_t *options = cairo_font_options_create();
        cairo_font_options_set_antialias(options, CAIRO_ANTIALIAS_GRAY);
        cairo_font_options_set_hint_style(options, CAIRO_HINT_STYLE_NONE);
        cairo_font_options_set_hint_metrics(options, CAIRO_HINT_METRICS_OFF);
        cairo_set_font_options(cr, options);
        cairo_font_options_destroy(options);
        cairo_set_font_face(cr, face);
        cairo_set_font_size(cr, 16);
        cairo_glyph_t glyph = {1, 16 + x, 32 + y};
        cairo_show_glyphs(cr, &glyph, 1);
    } else {
        cairo_rectangle(cr, 16 + x, 16 + y, 16, 16);
        cairo_fill(cr);
    }
    cairo_status_t status = cairo_status(cr);
    cairo_destroy(cr);
    if (status != CAIRO_STATUS_SUCCESS) {
        fprintf(stderr, "Render failed: %s\n", cairo_status_to_string(status));
        cairo_surface_destroy(surface);
        return NULL;
    }
    cairo_surface_flush(surface);
    return surface;
}

int main(void) {
    cairo_font_face_t *face = cairo_user_font_face_create();
    cairo_user_font_face_set_render_glyph_func(face, square_glyph);
    CHECK(cairo_font_face_status(face) == CAIRO_STATUS_SUCCESS);
    /* Cairo's Pixman glyph cache preserves quarter-pixel phases. The legacy
     * compositor rounds them to integers and fails these public-API checks. */
    for (int yphase = 0; yphase < 4; ++yphase) {
        for (int xphase = 0; xphase < 4; ++xphase) {
            double x = xphase / 4.0, y = yphase / 4.0;
            cairo_surface_t *glyph = render(face, x, y, 1);
            cairo_surface_t *reference = render(face, x, y, 0);
            CHECK(glyph && reference);
            const unsigned char *actual = cairo_image_surface_get_data(glyph);
            const unsigned char *expected = cairo_image_surface_get_data(reference);
            int actual_stride = cairo_image_surface_get_stride(glyph);
            int expected_stride = cairo_image_surface_get_stride(reference);
            for (int row = 0; row < 64; ++row) {
                for (int col = 0; col < 64; ++col) {
                    if (actual[row * actual_stride + col] !=
                        expected[row * expected_stride + col]) {
                        fprintf(stderr, "Glyph differs from geometry at phase (%g, %g), pixel (%d, %d): actual=%u expected=%u\n",
                                x, y, col, row, actual[row * actual_stride + col],
                                expected[row * expected_stride + col]);
                        return 1;
                    }
                }
            }
            cairo_surface_destroy(glyph);
            cairo_surface_destroy(reference);
        }
    }
    cairo_font_face_destroy(face);
    return 0;
}
