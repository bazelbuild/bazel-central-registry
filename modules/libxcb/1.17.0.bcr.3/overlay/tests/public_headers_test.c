#include <xcb/xcb.h>
#include <xcb/xcbext.h>
#include <xcb/shape.h>
#include <xcb/shm.h>
#include <xcb/xfixes.h>

int main(void) {
    return !xcb_shape_id.name || !xcb_shm_id.name || !xcb_xfixes_id.name;
}
