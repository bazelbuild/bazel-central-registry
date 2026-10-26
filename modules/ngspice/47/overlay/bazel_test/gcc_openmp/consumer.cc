#include <ngspice/sharedspice.h>
#include <omp.h>

#include <cstdio>
#include <cstring>

int main() {
  // Require both libraries in this executable. This query is valid before init.
  if (ngSpice_running()) return 1;

  // LLVM's omp.h remaps these calls to ompc_* symbols absent from libgomp.
  const char* format = "thread %n";
  char actual[64];
  omp_set_affinity_format(format);
  if (omp_get_affinity_format(actual, sizeof(actual)) != std::strlen(format) ||
      std::strcmp(actual, format) != 0) {
    std::fprintf(stderr, "OpenMP affinity API mismatch\n");
    return 1;
  }

  omp_lock_t lock;
  omp_init_lock(&lock);
  int count = 0;
  int threads = 0;
#pragma omp parallel num_threads(2) reduction(+ : threads)
  {
    threads += 1;
    for (int i = 0; i < 100; ++i) {
      omp_set_lock(&lock);
      ++count;
      omp_unset_lock(&lock);
    }
  }
  omp_destroy_lock(&lock);
  if (threads != 2 || count != 200) {
    std::fprintf(stderr, "Expected 2 threads and 200 locked increments, got %d and %d\n",
                 threads, count);
    return 1;
  }
  return 0;
}
