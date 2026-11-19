/* All generated client headers compile together and their interfaces link.
 * No compositor is needed: only static interface descriptions are touched. */

#include <stdio.h>
#include <string.h>

#include "cursor-shape-v1-client-protocol.h"
#include "fractional-scale-v1-client-protocol.h"
#include "tablet-unstable-v2-client-protocol.h"
#include "viewporter-client-protocol.h"
#include "xdg-activation-v1-client-protocol.h"
#include "xdg-decoration-unstable-v1-client-protocol.h"
#include "xdg-foreign-unstable-v2-client-protocol.h"
#include "xdg-shell-client-protocol.h"
#include "xdg-toplevel-icon-v1-client-protocol.h"

int main(void) {
  const struct wl_interface* interfaces[] = {
      &xdg_wm_base_interface,
      &xdg_activation_v1_interface,
      &zxdg_decoration_manager_v1_interface,
      &wp_fractional_scale_manager_v1_interface,
      &wp_viewporter_interface,
      &wp_cursor_shape_manager_v1_interface,
      &zwp_tablet_manager_v2_interface,
      &xdg_toplevel_icon_manager_v1_interface,
      &zxdg_exporter_v2_interface,
  };
  for (size_t i = 0; i < sizeof(interfaces) / sizeof(interfaces[0]); ++i) {
    printf("%s v%d\n", interfaces[i]->name, interfaces[i]->version);
    if (interfaces[i]->name == NULL || strlen(interfaces[i]->name) == 0) return 1;
  }
  return 0;
}
