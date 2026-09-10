#include <datrie/trie.h>
#include <cstdio>

#define CHECK(condition) do { if (!(condition)) { \
  std::fprintf(stderr, "Failed: %s at line %d\n", #condition, __LINE__); \
  return 1; } } while (0)

int main() {
  AlphaMap* alphabet = alpha_map_new();
  CHECK(alphabet && alpha_map_add_range(alphabet, 0x0e01, 0x0e5b) == 0);
  Trie* trie = trie_new(alphabet);
  alpha_map_free(alphabet);
  CHECK(trie);
  const AlphaChar thai[] = {0x0e44, 0x0e17, 0x0e22, 0}; // ไทย
  const AlphaChar missing[] = {0x0e01, 0};
  CHECK(trie_store(trie, thai, 42));
  TrieData value;
  CHECK(trie_retrieve(trie, thai, &value) && value == 42);
  CHECK(!trie_retrieve(trie, missing, &value));
  FILE* file = std::tmpfile();
  CHECK(file && trie_fwrite(trie, file) == 0);
  std::rewind(file);
  Trie* copy = trie_fread(file);
  std::fclose(file);
  CHECK(copy && trie_retrieve(copy, thai, &value) && value == 42);
  CHECK(trie_delete(copy, thai));
  CHECK(!trie_retrieve(copy, thai, &value));
  CHECK(trie_retrieve(trie, thai, &value) && value == 42);
  trie_free(copy);
  trie_free(trie);
  return 0;
}
