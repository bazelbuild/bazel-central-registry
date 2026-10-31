#include <cstddef>

#include <xkbcommon/xkbcommon-compose.h>
#include <xkbcommon/xkbcommon-keysyms.h>
#include <xkbcommon/xkbcommon.h>

namespace {

// Adapted from upstream libxkbcommon compose tests in test/compose.c,
// reduced to a single in-memory hermetic smoke test for BCR packaging.
constexpr char kComposeTable[] =
    "<Multi_key> <A> <T> : \"@\" at\n";

}  // namespace

int main() {
    xkb_context *ctx = xkb_context_new(XKB_CONTEXT_NO_DEFAULT_INCLUDES);
    if (ctx == nullptr) {
        return 1;
    }

    xkb_compose_table *table = xkb_compose_table_new_from_buffer(
        ctx,
        kComposeTable,
        sizeof(kComposeTable) - 1,
        "C",
        XKB_COMPOSE_FORMAT_TEXT_V1,
        XKB_COMPOSE_COMPILE_NO_FLAGS);
    if (table == nullptr) {
        xkb_context_unref(ctx);
        return 2;
    }

    xkb_compose_state *state =
        xkb_compose_state_new(table, XKB_COMPOSE_STATE_NO_FLAGS);
    if (state == nullptr) {
        xkb_compose_table_unref(table);
        xkb_context_unref(ctx);
        return 3;
    }

    if (xkb_compose_state_feed(state, XKB_KEY_Multi_key) !=
        XKB_COMPOSE_FEED_ACCEPTED) {
        xkb_compose_state_unref(state);
        xkb_compose_table_unref(table);
        xkb_context_unref(ctx);
        return 4;
    }

    if (xkb_compose_state_feed(state, XKB_KEY_A) != XKB_COMPOSE_FEED_ACCEPTED) {
        xkb_compose_state_unref(state);
        xkb_compose_table_unref(table);
        xkb_context_unref(ctx);
        return 5;
    }

    if (xkb_compose_state_feed(state, XKB_KEY_T) != XKB_COMPOSE_FEED_ACCEPTED) {
        xkb_compose_state_unref(state);
        xkb_compose_table_unref(table);
        xkb_context_unref(ctx);
        return 6;
    }

    const xkb_compose_status status = xkb_compose_state_get_status(state);
    const xkb_keysym_t keysym = xkb_compose_state_get_one_sym(state);

    xkb_compose_state_unref(state);
    xkb_compose_table_unref(table);
    xkb_context_unref(ctx);

    return status == XKB_COMPOSE_COMPOSED && keysym == XKB_KEY_at ? 0 : 7;
}
