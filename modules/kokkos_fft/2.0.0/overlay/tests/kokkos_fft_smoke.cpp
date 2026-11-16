// Smoke test for the Bazel-built KokkosFFT: runs FFTs through the FFTW
// backend on the host and checks them against known results. Needs no GPU;
// see BUILD.bazel.

#include <KokkosFFT.hpp>
#include <Kokkos_Core.hpp>

#include <cmath>
#include <cstdio>
#include <cstdlib>

#if defined(KOKKOS_ENABLE_CUDA) || defined(KOKKOS_ENABLE_HIP) \
    || defined(KOKKOS_ENABLE_SYCL)
#error "kokkos_fft_smoke is CPU-only; build it with --@kokkos//:device=none"
#endif

#if !defined(KOKKOSFFT_ENABLE_TPL_FFTW)
#error "kokkos_fft_smoke needs the FFTW TPL (@kokkos_fft//:default_config)"
#endif

namespace {

// Kokkos::Serial, not DefaultHostExecutionSpace: @fftw does not build FFTW's
// threads library, which KokkosFFT uses for plans on Kokkos::OpenMP/Threads.
using ExecSpace = Kokkos::Serial;
using RealView = Kokkos::View<double*, Kokkos::HostSpace>;
using ComplexView = Kokkos::View<Kokkos::complex<double>*, Kokkos::HostSpace>;

constexpr double kPi = 3.14159265358979323846;
constexpr double kTol = 1e-9;

int failures = 0;

void check(bool ok, const char* what)
{
  std::printf("[%s] %s\n", ok ? "PASS" : "FAIL", what);
  if (!ok) {
    ++failures;
  }
}

bool near(double a, double b)
{
  return std::abs(a - b) <= kTol * (1.0 + std::abs(b));
}

// rfft of a constant signal: all energy in the DC bin.
void test_rfft_constant()
{
  constexpr int n = 16;
  RealView x("x", n);
  ComplexView y("y", n / 2 + 1);
  Kokkos::deep_copy(x, 1.0);
  KokkosFFT::rfft(ExecSpace(), x, y);

  bool ok = near(y(0).real(), n) && near(y(0).imag(), 0.0);
  for (int k = 1; k <= n / 2; ++k) {
    ok = ok && near(Kokkos::abs(y(k)), 0.0);
  }
  check(ok, "rfft of a constant -> DC bin only");
}

// rfft of a cosine at frequency k0: magnitude n/2 at bin k0, zero elsewhere.
void test_rfft_cosine()
{
  constexpr int n = 64;
  constexpr int k0 = 5;
  RealView x("x", n);
  ComplexView y("y", n / 2 + 1);
  for (int i = 0; i < n; ++i) {
    x(i) = std::cos(2.0 * kPi * k0 * i / n);
  }
  KokkosFFT::rfft(ExecSpace(), x, y);

  bool ok = true;
  for (int k = 0; k <= n / 2; ++k) {
    ok = ok && near(Kokkos::abs(y(k)), k == k0 ? n / 2.0 : 0.0);
  }
  check(ok, "rfft of a cosine -> single peak at its frequency");
}

// irfft(rfft(x)) == x with the default (backward) normalization.
void test_rfft_irfft_roundtrip()
{
  constexpr int n = 30;
  RealView x("x", n);
  RealView x_back("x_back", n);
  ComplexView y("y", n / 2 + 1);
  for (int i = 0; i < n; ++i) {
    x(i) = std::sin(0.37 * i) + 0.25 * i;
  }
  // FFTW's complex-to-real transform overwrites its input, so copy it.
  ComplexView y_copy("y_copy", n / 2 + 1);
  KokkosFFT::rfft(ExecSpace(), x, y);
  Kokkos::deep_copy(y_copy, y);
  KokkosFFT::irfft(ExecSpace(), y_copy, x_back);

  bool ok = true;
  for (int i = 0; i < n; ++i) {
    ok = ok && near(x_back(i), x(i));
  }
  check(ok, "irfft(rfft(x)) == x");
}

// Reusable plans (KokkosFFT::Plan + execute): complex fft then ifft.
void test_plan_roundtrip()
{
  constexpr int n = 24;
  ComplexView x("x", n);
  ComplexView y("y", n);
  ComplexView x_back("x_back", n);
  for (int i = 0; i < n; ++i) {
    x(i) = Kokkos::complex<double>(std::cos(0.5 * i), 0.1 * i);
  }

  KokkosFFT::Plan<ExecSpace, ComplexView, ComplexView> forward(
      ExecSpace(), x, y, KokkosFFT::Direction::forward, /*axis=*/-1);
  KokkosFFT::Plan<ExecSpace, ComplexView, ComplexView> backward(
      ExecSpace(), y, x_back, KokkosFFT::Direction::backward, /*axis=*/-1);

  bool ok = true;
  for (int run = 0; run < 2; ++run) {  // plans must be reusable
    KokkosFFT::execute(forward, x, y);
    KokkosFFT::execute(backward, y, x_back);
    for (int i = 0; i < n; ++i) {
      ok = ok && near(x_back(i).real(), x(i).real())
           && near(x_back(i).imag(), x(i).imag());
    }
  }
  check(ok, "Plan + execute: ifft(fft(x)) == x, plans reused");
}

}  // namespace

int main(int argc, char* argv[])
{
  Kokkos::ScopeGuard guard(argc, argv);

  std::printf("KokkosFFT %d.%d.%d on Kokkos %d.%d.%d, execution space: %s\n",
              KOKKOSFFT_VERSION_MAJOR,
              KOKKOSFFT_VERSION_MINOR,
              KOKKOSFFT_VERSION_PATCH,
              KOKKOS_VERSION_MAJOR,
              KOKKOS_VERSION_MINOR,
              KOKKOS_VERSION_PATCH,
              ExecSpace::name());

  test_rfft_constant();
  test_rfft_cosine();
  test_rfft_irfft_roundtrip();
  test_plan_roundtrip();

  return failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
