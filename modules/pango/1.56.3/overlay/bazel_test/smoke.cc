#include <pango/pango.h>
#include <pango/pangocairo.h>
#include <pango/pangoft2.h>
#include <cstring>

int main() {
  if (pango_version() != PANGO_VERSION_ENCODE(1, 56, 3) ||
      std::strcmp(pango_version_string(), "1.56.3") != 0) return 1;
  PangoFontDescription *desc = pango_font_description_from_string("Sans 12");
  if (!desc || pango_font_description_get_size(desc) != 12 * PANGO_SCALE) return 2;
  pango_font_description_free(desc);
  if (!pango_cairo_font_map_get_type() || !pango_ft2_font_map_get_type()) return 3;
  return 0;
}
