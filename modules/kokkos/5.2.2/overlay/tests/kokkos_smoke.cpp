// Smoke test for the Bazel-built Kokkos: initializes the runtime and runs a
// few kernels on the host. Needs no GPU; see BUILD.bazel.

#include <Kokkos_Core.hpp>
#include <Kokkos_UnorderedMap.hpp>

#include <cstdio>
#include <cstdlib>

#if defined(KOKKOS_ENABLE_CUDA) || defined(KOKKOS_ENABLE_HIP) \
    || defined(KOKKOS_ENABLE_SYCL)
#error "kokkos_smoke is CPU-only; build it with --@kokkos//:device=none"
#endif

namespace {

using ExecSpace = Kokkos::DefaultHostExecutionSpace;
using MemSpace = Kokkos::HostSpace;
using Policy = Kokkos::RangePolicy<ExecSpace>;

int failures = 0;

void check(bool ok, const char* what)
{
  std::printf("[%s] %s\n", ok ? "PASS" : "FAIL", what);
  if (!ok) {
    ++failures;
  }
}

void test_parallel_for_and_reduce()
{
  constexpr int n = 10000;
  Kokkos::View<double*, MemSpace> v("v", n);
  Kokkos::parallel_for(
      "fill", Policy(0, n), KOKKOS_LAMBDA(const int i) { v(i) = i; });

  double sum = 0.0;
  Kokkos::parallel_reduce(
      "sum",
      Policy(0, n),
      KOKKOS_LAMBDA(const int i, double& acc) { acc += v(i); },
      sum);
  check(sum == n * (n - 1) / 2.0, "parallel_for + parallel_reduce (sum)");

  int max = 0;
  Kokkos::parallel_reduce(
      "max",
      Policy(0, n),
      KOKKOS_LAMBDA(const int i, int& acc) {
        if (static_cast<int>(v(i)) > acc) {
          acc = static_cast<int>(v(i));
        }
      },
      Kokkos::Max<int>(max));
  check(max == n - 1, "parallel_reduce (Kokkos::Max)");
}

void test_mirror_and_deep_copy()
{
  constexpr int n = 64;
  Kokkos::View<int*, MemSpace> a("a", n);
  Kokkos::deep_copy(a, 7);
  auto mirror = Kokkos::create_mirror_view_and_copy(Kokkos::HostSpace(), a);
  bool ok = true;
  for (int i = 0; i < n; ++i) {
    ok = ok && mirror(i) == 7;
  }
  check(ok, "deep_copy + create_mirror_view_and_copy");
}

void test_unordered_map()
{
  constexpr int n = 1000;
  Kokkos::UnorderedMap<int, int, ExecSpace> map(2 * n);
  Kokkos::parallel_for(
      "insert", Policy(0, n), KOKKOS_LAMBDA(const int i) {
        map.insert(i, 2 * i);
      });
  Kokkos::fence();
  const int idx = map.find(n / 2);
  check(map.size() == n && map.valid_at(idx)
            && map.value_at(idx) == n,
        "UnorderedMap insert/find (containers)");
}

}  // namespace

int main(int argc, char* argv[])
{
  Kokkos::ScopeGuard guard(argc, argv);

  std::printf("Kokkos %d.%d.%d, host execution space: %s, concurrency: %d\n",
              KOKKOS_VERSION_MAJOR,
              KOKKOS_VERSION_MINOR,
              KOKKOS_VERSION_PATCH,
              ExecSpace::name(),
              ExecSpace().concurrency());

  test_parallel_for_and_reduce();
  test_mirror_and_deep_copy();
  test_unordered_map();

  return failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
