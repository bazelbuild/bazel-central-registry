#include <xkbcommon/xkbcommon-compat.h>
#include <xkbcommon/xkbcommon-compose.h>
#include <xkbcommon/xkbcommon-keysyms.h>
#include <xkbcommon/xkbcommon-names.h>
#include <xkbcommon/xkbcommon.h>

int main() {
    const int symbols =
        XKB_CONTEXT_NO_FLAGS +
        XKB_COMPOSE_COMPILE_NO_FLAGS +
        XKB_KEY_NoSymbol +
        static_cast<int>(XKB_MOD_NAME_SHIFT[0]) +
        static_cast<int>(XKB_KEYSYM_CASE_INSENSITIVE);
    (void)symbols;
    return 0;
}
