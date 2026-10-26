#include <cairo-gobject.h>
int main(void) {
  if (!g_type_is_a(cairo_gobject_context_get_type(), G_TYPE_BOXED)) return 1;
  if (!g_type_is_a(cairo_gobject_surface_get_type(), G_TYPE_BOXED)) return 2;
  if (!g_type_is_a(cairo_gobject_format_get_type(), G_TYPE_ENUM)) return 3;
  cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 2, 2);
  GValue value = G_VALUE_INIT;
  g_value_init(&value, cairo_gobject_surface_get_type());
  g_value_set_boxed(&value, surface);
  cairo_surface_destroy(surface);
  surface = g_value_get_boxed(&value);
  if (cairo_surface_status(surface) != CAIRO_STATUS_SUCCESS) return 4;
  g_value_unset(&value);
  return 0;
}
