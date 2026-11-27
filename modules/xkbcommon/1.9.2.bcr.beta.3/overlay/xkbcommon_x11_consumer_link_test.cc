// Checks that a consumer can include <xkbcommon/xkbcommon-x11.h> and link
// @xkbcommon//:xkbcommon-x11 (including the internal symbols it takes from
// :xkbcommon). It does not call into X11, since there is no X server in CI.
#include <xkbcommon/xkbcommon-x11.h>

int main() {
    volatile auto get_device_id = &xkb_x11_get_core_keyboard_device_id;
    volatile auto keymap_new = &xkb_x11_keymap_new_from_device;
    volatile auto state_new = &xkb_x11_state_new_from_device;
    if (get_device_id == nullptr || keymap_new == nullptr ||
        state_new == nullptr) {
        return 1;
    }
    return XKB_X11_MIN_MAJOR_XKB_VERSION == 1 ? 0 : 1;
}
