#define SDL_MAIN_HANDLED
#include <SDL2/SDL.h>

int main(int argc, char** argv) {
  (void)argc;
  (void)argv;
  return SDL_WasInit(0);
}
