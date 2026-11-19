// Parallel sort of a large random vector must match std::sort, repeatedly (the
// repetitions exercise the thread pool's completion semaphore).

#include <algorithm>
#include <cstdio>
#include <random>
#include <vector>

#include <ppqsort.h>

int main() {
  std::mt19937_64 rng(12345);
  for (int round = 0; round < 20; ++round) {
    std::vector<long long> data(1 << 20);
    for (auto& v : data) v = static_cast<long long>(rng());
    std::vector<long long> expected = data;
    std::sort(expected.begin(), expected.end());
    ppqsort::sort(ppqsort::execution::par, data.begin(), data.end(), 4);
    if (data != expected) {
      std::fprintf(stderr, "round %d: parallel sort mismatch\n", round);
      return 1;
    }
  }
  std::vector<int> small = {5, 3, 1, 4, 2};
  ppqsort::sort(small.begin(), small.end());
  if (!std::is_sorted(small.begin(), small.end())) return 1;
  return 0;
}
