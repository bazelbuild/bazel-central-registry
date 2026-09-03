#include <thai/thbrk.h>
#include <thai/thwbrk.h>
#include "rules_cc/cc/runfiles/runfiles.h"

#include <cstdio>
#include <cstdlib>
#include <memory>
#include <string>

#define CHECK(condition) do { if (!(condition)) { \
  std::fprintf(stderr, "Failed: %s at line %d\n", #condition, __LINE__); \
  return 1; } } while (0)

int main(int argc, char** argv) {
  CHECK(argc == 2);
  std::string error;
  std::unique_ptr<rules_cc::cc::runfiles::Runfiles> rf(
      rules_cc::cc::runfiles::Runfiles::CreateForTest(BAZEL_CURRENT_REPOSITORY, &error));
  CHECK(rf);
  const std::string dictionary = rf->Rlocation(argv[1]);
  CHECK(!dictionary.empty());
  // Missing data must not fall back to a host-installed dictionary.
  CHECK(th_brk_new(nullptr) == nullptr);
  ThBrk* explicit_brk = th_brk_new(dictionary.c_str());
  CHECK(explicit_brk);
  const std::string directory = dictionary.substr(0, dictionary.find_last_of('/'));
  CHECK(setenv("LIBTHAI_DICTDIR", directory.c_str(), 1) == 0);
  ThBrk* default_brk = th_brk_new(nullptr);
  CHECK(default_brk);
  // An upstream test sentence with seven known word boundaries.
  const thwchar_t text[] = L"สวัสดีครับ กอ.รมน. นี่เป็นการทดสอบตัวเอง";
  const int expected[] = {6, 11, 19, 22, 26, 29, 34};
  for (ThBrk* brk : {explicit_brk, default_brk}) {
    int positions[40] = {};
    const int count = th_brk_wc_find_breaks(brk, text, positions, 40);
    CHECK(count == 7);
    for (int i = 0; i < count; ++i) CHECK(positions[i] == expected[i]);
    th_brk_delete(brk);
  }
  return 0;
}
