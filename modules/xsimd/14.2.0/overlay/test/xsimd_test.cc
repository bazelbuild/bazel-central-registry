#include "xsimd/xsimd.hpp"

int main() {
  using batch = xsimd::batch<float>;
  const batch values(1.0F);
  return xsimd::reduce_add(values) == static_cast<float>(batch::size) ? 0 : 1;
}
