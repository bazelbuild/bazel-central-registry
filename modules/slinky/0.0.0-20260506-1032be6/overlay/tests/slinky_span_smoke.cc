#include "slinky/base/span.h"

int main() {
  const int values[] = {1, 2, 3};
  slinky::span<const int> span(values);
  return span.size() == 3 && span.front() == 1 && span.back() == 3 ? 0 : 1;
}
