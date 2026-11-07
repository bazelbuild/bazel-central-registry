#include <xkbcommon/xkbcommon.h>

int main() {
    xkb_context *ctx = xkb_context_new(XKB_CONTEXT_NO_DEFAULT_INCLUDES);
    if (ctx == nullptr) {
        return 1;
    }
    xkb_context_unref(ctx);
    return 0;
}
