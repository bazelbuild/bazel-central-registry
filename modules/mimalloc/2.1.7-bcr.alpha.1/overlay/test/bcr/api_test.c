#include <mimalloc.h>

#include <stdio.h>
#include <string.h>

static bool found_not_freed;

void out_func(const char *msg, void *arg) {
  printf("%s", msg);
  if (strstr(msg, "not all freed") != NULL) {
    found_not_freed = true;
  }
}

int main(int argc, char** argv) {
  void *p = mi_malloc(1234);

  found_not_freed = false;
  mi_stats_print_out(out_func, NULL);
  if (!found_not_freed) {
    printf("Memory leak not detected\n");
    return 1;
  }

  mi_free(p);
}
