#include <grpc/support/alloc.h>

int main() {
  void* value = gpr_malloc(1);
  gpr_free(value);
  return value == nullptr ? 1 : 0;
}
