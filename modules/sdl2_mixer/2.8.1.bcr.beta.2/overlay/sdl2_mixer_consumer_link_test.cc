#include "SDL_mixer.h"

int main(int argc, char** argv) {
  (void)argc;
  (void)argv;
  return Mix_Linked_Version() == nullptr;
}
