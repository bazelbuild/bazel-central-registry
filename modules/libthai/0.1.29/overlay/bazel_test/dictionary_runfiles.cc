#include <thai/thbrk.h>
#include <thai/thwbrk.h>
#include <datrie/trie.h>
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
  // Explicit missing files must fail instead of silently selecting a fallback.
  CHECK(th_brk_new("/nonexistent/libthai/missing.tri") == nullptr);
  CHECK(unsetenv("LIBTHAI_DICTDIR") == 0);
  ThBrk* bundled_brk = th_brk_new(nullptr);
  CHECK(bundled_brk);
  ThBrk* explicit_brk = th_brk_new(dictionary.c_str());
  CHECK(explicit_brk);
  const std::string directory = dictionary.substr(0, dictionary.find_last_of('/'));
  CHECK(setenv("LIBTHAI_DICTDIR", directory.c_str(), 1) == 0);
  ThBrk* default_brk = th_brk_new(nullptr);
  CHECK(default_brk);
  // An upstream test sentence with seven known word boundaries.
  const thwchar_t text[] = L"สวัสดีครับ กอ.รมน. นี่เป็นการทดสอบตัวเอง";
  const int expected[] = {6, 11, 19, 22, 26, 29, 34};
  for (ThBrk* brk : {explicit_brk, default_brk, bundled_brk}) {
    int positions[40] = {};
    const int count = th_brk_wc_find_breaks(brk, text, positions, 40);
    CHECK(count == 7);
    for (int i = 0; i < count; ++i) CHECK(positions[i] == expected[i]);
    th_brk_delete(brk);
  }
  // A custom dictionary deliberately treats this compound as one word.
  // Both overrides must take precedence over the bundled word boundaries.
  const thwchar_t compound[] = L"สวัสดีครับ";
  AlphaChar key[40] = {};
  for (unsigned i = 0; compound[i]; ++i) key[i] = compound[i];
  AlphaMap* map = alpha_map_new();
  CHECK(map);
  CHECK(alpha_map_add_range(map, 0x0E01, 0x0E5B) == 0);
  Trie* trie = trie_new(map);
  alpha_map_free(map);
  CHECK(trie);
  CHECK(trie_store(trie, key, 1));
  const char* tmp = std::getenv("TEST_TMPDIR");
  CHECK(tmp);
  const std::string custom_path = std::string(tmp) + "/thbrk.tri";
  CHECK(trie_save(trie, custom_path.c_str()) == 0);
  trie_free(trie);
  ThBrk* custom_explicit = th_brk_new(custom_path.c_str());
  CHECK(custom_explicit);
  CHECK(setenv("LIBTHAI_DICTDIR", tmp, 1) == 0);
  ThBrk* custom_default = th_brk_new(nullptr);
  CHECK(custom_default);
  for (ThBrk* brk : {custom_explicit, custom_default}) {
    int positions[40] = {};
    CHECK(th_brk_wc_find_breaks(brk, compound, positions, 40) == 0);
    th_brk_delete(brk);
  }
  CHECK(unsetenv("LIBTHAI_DICTDIR") == 0);
  ThBrk* bundled_again = th_brk_new(nullptr);
  CHECK(bundled_again);
  int positions[40] = {};
  CHECK(th_brk_wc_find_breaks(bundled_again, compound, positions, 40) == 1);
  CHECK(positions[0] == 6);
  th_brk_delete(bundled_again);
  return 0;
}
