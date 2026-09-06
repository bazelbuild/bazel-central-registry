#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char** argv) {
  // Concatenate all arguments into a single string.
  size_t len = 0;
  for (int i = 1; i < argc; i++) {
    len += strlen(argv[i]);
  }
  char* str = malloc(len + 1);
  str[0] = '\0';
  for (int i = 1; i < argc; i++) {
    strcat(str, argv[i]);
  }
  printf("%s\n", str);
  free(str);
  return 0;
}
