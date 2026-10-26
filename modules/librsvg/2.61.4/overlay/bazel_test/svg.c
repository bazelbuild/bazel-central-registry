#include <gdk-pixbuf/gdk-pixbuf.h>
#include <string.h>
#include <librsvg/rsvg.h>
int main(void) {
  if (rsvg_major_version != 2 || rsvg_minor_version != 61 || rsvg_micro_version != 4) return 6;
  const char *svg = "<svg xmlns='http://www.w3.org/2000/svg' width='2' height='3'><rect width='2' height='3' fill='#ff0000'/></svg>";
  GError *error = NULL;
  GdkPixbufLoader *loader = gdk_pixbuf_loader_new_with_type("svg", &error);
  if (!loader || error) return 1;
  if (!gdk_pixbuf_loader_write(loader, (const guchar *)svg, strlen(svg), &error)) return 2;
  if (!gdk_pixbuf_loader_close(loader, &error)) return 3;
  GdkPixbuf *pixbuf = gdk_pixbuf_loader_get_pixbuf(loader);
  if (!pixbuf || gdk_pixbuf_get_width(pixbuf) != 2 || gdk_pixbuf_get_height(pixbuf) != 3) return 4;
  const guchar *pixels = gdk_pixbuf_read_pixels(pixbuf);
  if (pixels[0] != 255 || pixels[1] != 0 || pixels[2] != 0 || pixels[3] != 255) return 5;
  g_object_unref(loader);
  return 0;
}
