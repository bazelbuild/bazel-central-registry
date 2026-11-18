// Builds a tiny dense index through the public headers and queries it.
#include <usearch/index.hpp>
#include <usearch/index_dense.hpp>
#include <usearch/index_plugins.hpp>

#include <cstdio>
#include <utility>

using namespace unum::usearch;

int main() {
    metric_punned_t metric(3, metric_kind_t::l2sq_k, scalar_kind_t::f32_k);
    auto made = index_dense_t::make(metric);
    if (!made) {
        std::fprintf(stderr, "make failed: %s\n", made.error.what());
        return 1;
    }
    index_dense_t index = std::move(made.index);
    if (!index.try_reserve(10))
        return 1;

    float const a[3] = {0.1f, 0.3f, 0.2f};
    float const b[3] = {0.9f, 0.1f, 0.5f};
    if (!index.add(42, a) || !index.add(43, b))
        return 1;

    auto results = index.search(a, 1);
    if (!results || results.size() != 1 || results[0].member.key != 42) {
        std::fprintf(stderr, "unexpected search result\n");
        return 1;
    }
    std::printf("usearch smoke test: found key %d\n", static_cast<int>(results[0].member.key));
    return 0;
}
