#include <xcb/xcb.h>
#include <xcb/xcbext.h>
#include <xcb/shape.h>
#include <xcb/shm.h>
#include <xcb/xfixes.h>

/* libxcb's private headers, and its public ones without the xcb/ prefix, must
   not be on consumers' include paths. A leaked config.h in particular shadows
   the consumer's own. */
#if __has_include(<config.h>) || __has_include(<xcbint.h>) || \
    __has_include(<xcb.h>) || __has_include(<bigreq.h>)
#error libxcb leaks private include paths to its consumers
#endif

int main(void) {
    return !xcb_shape_id.name || !xcb_shm_id.name || !xcb_xfixes_id.name;
}
