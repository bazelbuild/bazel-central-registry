// Index 1000 random vectors and check that each finds itself as the nearest
// neighbour (cosine metric), as Tracy's LLM embeddings index does.

#include <cstdio>
#include <random>
#include <vector>

#include <usearch/index_dense.hpp>

using namespace unum::usearch;

int main() {
  constexpr std::size_t dims = 64;
  constexpr std::size_t count = 1000;
  metric_punned_t metric(dims, metric_kind_t::cos_k, scalar_kind_t::f32_k);
  auto made = index_dense_t::make(metric);
  if (!made) {
    std::fprintf(stderr, "make failed: %s\n", made.error.release());
    return 1;
  }
  index_dense_t index = std::move(made.index);
  index.reserve(count);

  std::mt19937 rng(42);
  std::normal_distribution<float> dist;
  std::vector<std::vector<float>> vectors(count, std::vector<float>(dims));
  for (std::size_t i = 0; i < count; ++i) {
    for (auto& x : vectors[i]) x = dist(rng);
    if (!index.add(i, vectors[i].data())) return 1;
  }

  std::size_t hits = 0;
  for (std::size_t i = 0; i < count; ++i) {
    auto result = index.search(vectors[i].data(), 1);
    if (result.size() == 1 && result[0].member.key == i) ++hits;
  }
  std::printf("self-recall: %zu / %zu\n", hits, count);
  return hits >= count * 99 / 100 ? 0 : 1;
}
