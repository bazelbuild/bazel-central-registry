#include <stdlib.h>
#include <string.h>

#include "demangle.h"

int main(void) {
  char* demangled = cplus_demangle_v3("_Z3foov", DMGL_PARAMS | DMGL_ANSI);
  if (demangled == NULL) {
    return 1;
  }

  int matches = strcmp(demangled, "foo()") == 0;
  free(demangled);
  return matches ? 0 : 1;
}
