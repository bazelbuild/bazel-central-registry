#include <pthreadpool.h>

int main() {
  pthreadpool_t pool = pthreadpool_create(1);
  if (pool == nullptr) {
    return 1;
  }
  pthreadpool_destroy(pool);
  return 0;
}
