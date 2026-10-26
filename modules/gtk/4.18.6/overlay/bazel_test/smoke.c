#include <gtk/gtk.h>
#include <gdk/x11/gdkx.h>
int main(void) {
  if (gtk_get_major_version() != 4 || gtk_get_minor_version() != 18) return 1;
  if (gtk_check_version(4, 18, 6) != NULL) return 2;
  GtkStringList *items = gtk_string_list_new((const char *[]) {"one", "two", NULL});
  if (g_list_model_get_n_items(G_LIST_MODEL(items)) != 2) return 3;
  g_object_unref(items);
  GdkRGBA color;
  if (!gdk_rgba_parse(&color, "#ff0000") || color.red != 1) return 4;
  return gdk_x11_display_get_type() == G_TYPE_INVALID;
}
