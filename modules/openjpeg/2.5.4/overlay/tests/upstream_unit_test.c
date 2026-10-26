#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#include <direct.h>
#define chdir _chdir
#else
#include <unistd.h>
#endif

#define main upstream_empty_image_test
#include "unit/testempty1.c"
#undef main

int main(int argc, char **argv) {
  const char *tmpdir = getenv("TEST_TMPDIR");
  if (tmpdir == NULL || chdir(tmpdir) != 0) {
    fprintf(stderr, "cannot enter Bazel's writable test directory\n");
    return 1;
  }
  return upstream_empty_image_test(argc, argv);
}
