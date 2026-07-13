// Smoke test for the faiss C API (`faiss_c`). Exercises the public
// <faiss/c_api/...> headers and the C ABI end to end: build a Flat index via
// the factory, add vectors, and run a self-query.

#include <gtest/gtest.h>

#include <vector>

#include <faiss/c_api/Index_c.h>
#include <faiss/c_api/error_c.h>
#include <faiss/c_api/index_factory_c.h>

TEST(FaissCApi, FlatIndexFactoryAddSearch) {
    const int d = 16;

    FaissIndex* index = nullptr;
    ASSERT_EQ(faiss_index_factory(&index, d, "Flat", METRIC_L2), 0)
            << faiss_get_last_error();
    ASSERT_NE(index, nullptr);
    EXPECT_TRUE(faiss_Index_is_trained(index));

    const int nb = 64;
    std::vector<float> xb(static_cast<size_t>(nb) * d);
    for (int i = 0; i < nb; i++) {
        for (int j = 0; j < d; j++) {
            xb[i * d + j] =
                    static_cast<float>(i) + static_cast<float>(j) * 0.001f;
        }
    }

    ASSERT_EQ(faiss_Index_add(index, nb, xb.data()), 0)
            << faiss_get_last_error();
    EXPECT_EQ(faiss_Index_ntotal(index), static_cast<idx_t>(nb));

    const int nq = 5;
    const int k = 3;
    std::vector<idx_t> labels(static_cast<size_t>(nq) * k);
    std::vector<float> distances(static_cast<size_t>(nq) * k);
    ASSERT_EQ(
            faiss_Index_search(
                    index, nq, xb.data(), k, distances.data(), labels.data()),
            0)
            << faiss_get_last_error();

    // Each database vector, used as its own query, is its own nearest
    // neighbour at distance 0.
    for (int i = 0; i < nq; i++) {
        EXPECT_EQ(labels[i * k], static_cast<idx_t>(i));
        EXPECT_FLOAT_EQ(distances[i * k], 0.0f);
    }

    faiss_Index_free(index);
}
