// Smoke test for the ppqsort Bazel module: sorts with each execution policy
// and checks the result against std::sort.

#include <ppqsort.h>

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <random>
#include <string>
#include <vector>

namespace {

int failures = 0;

template <typename T, typename Compare = std::less<>>
void Check(const char* what, const std::vector<T>& got, std::vector<T> want,
           Compare comp = Compare()) {
  std::sort(want.begin(), want.end(), comp);
  if (got != want) {
    std::fprintf(stderr, "FAIL: %s\n", what);
    ++failures;
  }
}

}  // namespace

int main() {
  std::mt19937 rng(42);
  std::uniform_int_distribution<int> dist(-1000000, 1000000);
  std::vector<int> input(1 << 20);
  for (auto& v : input) v = dist(rng);

  {
    auto v = input;
    ppqsort::sort(v.begin(), v.end());
    Check("default", v, input);
  }
  {
    auto v = input;
    ppqsort::sort(ppqsort::execution::seq, v.begin(), v.end());
    Check("seq", v, input);
  }
  {
    auto v = input;
    ppqsort::sort(ppqsort::execution::par, v.begin(), v.end());
    Check("par", v, input);
  }
  {
    auto v = input;
    ppqsort::sort(ppqsort::execution::par, v.begin(), v.end(), 4);
    Check("par, 4 threads", v, input);
  }
  {
    auto v = input;
    ppqsort::sort(ppqsort::execution::par_force_branchless, v.begin(), v.end());
    Check("par_force_branchless", v, input);
  }
  {
    auto v = input;
    ppqsort::sort(ppqsort::execution::par, v.begin(), v.end(), std::greater<>());
    Check("par, std::greater", v, input, std::greater<>());
  }
  {
    std::vector<std::string> s;
    for (int i = 0; i < 100000; ++i) s.push_back(std::to_string(dist(rng)));
    auto v = s;
    ppqsort::sort(ppqsort::execution::par, v.begin(), v.end());
    Check("par, strings", v, s);
  }

  if (failures == 0) std::puts("PASS");
  return failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
