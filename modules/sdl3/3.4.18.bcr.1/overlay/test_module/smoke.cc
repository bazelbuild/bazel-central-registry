#include <SDL3/SDL_log.h>
#include <SDL3/SDL_version.h>

// The headers a consumer compiles against and the library it links must be the
// same SDL.
auto main(int /*argc*/, char** /*argv*/) -> int {
    const int compiled = SDL_VERSION;
    const int linked = SDL_GetVersion();

    SDL_Log("Compiled against SDL %d.%d.%d, linked against SDL %d.%d.%d",
            SDL_VERSIONNUM_MAJOR(compiled), SDL_VERSIONNUM_MINOR(compiled),
            SDL_VERSIONNUM_MICRO(compiled), SDL_VERSIONNUM_MAJOR(linked),
            SDL_VERSIONNUM_MINOR(linked), SDL_VERSIONNUM_MICRO(linked));

    return compiled == linked ? 0 : 1;
}
