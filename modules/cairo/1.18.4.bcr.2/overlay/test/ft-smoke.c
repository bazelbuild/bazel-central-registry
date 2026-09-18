#include <cairo-ft.h>
#include <fontconfig/fontconfig.h>
#include <fontconfig/fcfreetype.h>
#include <stdio.h>

#if !CAIRO_HAS_FT_FONT || !CAIRO_HAS_FC_FONT
#error Cairo must provide FreeType and fontconfig support
#endif

#define CHECK(condition) do { if (!(condition)) { \
    fprintf(stderr, "Failed: %s at line %d\n", #condition, __LINE__); \
    return 1; } } while (0)

/* One synthetic bitmap glyph keeps this test independent of installed fonts. */
static const unsigned char font[] =
    "STARTFONT 2.1\n"
    "FONT -test-smoke-medium-r-normal--8-80-75-75-c-80-iso10646-1\n"
    "SIZE 8 75 75\n"
    "FONTBOUNDINGBOX 8 8 0 0\n"
    "STARTPROPERTIES 4\n"
    "FONT_ASCENT 8\n"
    "FONT_DESCENT 0\n"
    "CHARSET_REGISTRY \"ISO10646\"\n"
    "CHARSET_ENCODING \"1\"\n"
    "ENDPROPERTIES\n"
    "CHARS 1\n"
    "STARTCHAR A\n"
    "ENCODING 65\n"
    "SWIDTH 1000 0\n"
    "DWIDTH 8 0\n"
    "BBX 8 8 0 0\n"
    "BITMAP\n"
    "18\n24\n42\n7E\n42\n42\n42\n00\n"
    "ENDCHAR\n"
    "ENDFONT\n";

static int render(cairo_font_face_t *face) {
    CHECK(cairo_font_face_status(face) == CAIRO_STATUS_SUCCESS);
    CHECK(cairo_font_face_get_type(face) == CAIRO_FONT_TYPE_FT);
    cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_A8, 32, 32);
    cairo_t *cr = cairo_create(surface);
    cairo_set_font_face(cr, face);
    cairo_set_font_size(cr, 8);
    cairo_move_to(cr, 8, 16);
    cairo_show_text(cr, "A");
    CHECK(cairo_status(cr) == CAIRO_STATUS_SUCCESS);
    cairo_surface_flush(surface);
    const unsigned char *pixels = cairo_image_surface_get_data(surface);
    const int stride = cairo_image_surface_get_stride(surface);
    int ink = 0;
    for (int y = 0; y < 32; ++y)
        for (int x = 0; x < 32; ++x)
            ink += pixels[y * stride + x] != 0;
    CHECK(ink > 0);
    cairo_destroy(cr);
    cairo_surface_destroy(surface);
    return 0;
}

int main(void) {
    FT_Library library;
    FT_Face ft_face;
    CHECK(FT_Init_FreeType(&library) == 0);
    CHECK(FT_New_Memory_Face(library, font, sizeof(font) - 1, 0, &ft_face) == 0);
    CHECK(FT_Get_Char_Index(ft_face, 'A') != 0);

    cairo_font_face_t *face = cairo_ft_font_face_create_for_ft_face(ft_face, 0);
    CHECK(render(face) == 0);
    cairo_font_face_destroy(face);

    /* An explicit FT face bypasses fontconfig's installed-font discovery. */
    FcPattern *pattern = FcPatternCreate();
    CHECK(pattern);
    CHECK(FcPatternAddFTFace(pattern, FC_FT_FACE, ft_face));
    face = cairo_ft_font_face_create_for_pattern(pattern);
    CHECK(render(face) == 0);
    cairo_font_face_destroy(face);
    FcPatternDestroy(pattern);

    /* FreeType faces must outlive Cairo's scaled-font cache. */
    cairo_debug_reset_static_data();
    CHECK(FT_Done_Face(ft_face) == 0);
    CHECK(FT_Done_FreeType(library) == 0);
    return 0;
}
