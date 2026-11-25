#include <SDL3_mixer/SDL_mixer.h>

int main(int argc, char** argv) {
  (void)argc;
  (void)argv;
  return MIX_Version() == 0;
}
