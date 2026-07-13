// GPU smoke test for the faiss C API (`faiss_c` built with CUDA). Builds a CPU
// Flat index, moves it to the GPU via StandardGpuResources, then adds vectors
// and runs a self-query. Exercises the public <faiss/c_api/gpu/...> headers and
// the GPU backend end to end.
//
// This target is gated with `target_compatible_with = requires_cuda()`, so it is
// only built where CUDA is enabled and a toolchain is configured (i.e. locally,
// not on the CPU-only BCR CI). It also needs a GPU at run time and skips
// gracefully when none is present.

#include <gtest/gtest.h>

#include <vector>

#include <faiss/c_api/Index_c.h>
#include <faiss/c_api/error_c.h>
#include <faiss/c_api/gpu/DeviceUtils_c.h>
#include <faiss/c_api/gpu/GpuAutoTune_c.h>
#include <faiss/c_api/gpu/GpuClonerOptions_c.h>
#include <faiss/c_api/gpu/StandardGpuResources_c.h>
#include <faiss/c_api/index_factory_c.h>

TEST(FaissCApiGpu, FlatIndexCpuToGpuSearch) {
    int ngpus = 0;
    ASSERT_EQ(faiss_get_num_gpus(&ngpus), 0) << faiss_get_last_error();
    if (ngpus < 1) {
        GTEST_SKIP() << "no CUDA device available";
    }

    FaissStandardGpuResources* res = nullptr;
    ASSERT_EQ(faiss_StandardGpuResources_new(&res), 0)
            << faiss_get_last_error();

    const int d = 16;
    FaissIndex* cpu_index = nullptr;
    ASSERT_EQ(faiss_index_factory(&cpu_index, d, "Flat", METRIC_L2), 0)
            << faiss_get_last_error();

    FaissGpuClonerOptions* options = nullptr;
    ASSERT_EQ(faiss_GpuClonerOptions_new(&options), 0)
            << faiss_get_last_error();

    // FaissGpuIndex and FaissStandardGpuResources are typedef'd to the same
    // opaque structs as their base classes (FaissIndex / FaissGpuResources
    // provider), so the base faiss_Index_* calls apply directly.
    FaissGpuIndex* index = nullptr;
    ASSERT_EQ(
            faiss_index_cpu_to_gpu_with_options(
                    res, 0, cpu_index, options, &index),
            0)
            << faiss_get_last_error();

    const int nb = 64;
    std::vector<float> xb(static_cast<size_t>(nb) * d);
    for (int i = 0; i < nb; i++) {
        for (int j = 0; j < d; j++) {
            xb[i * d + j] =
                    static_cast<float>(i) * 0.1f + static_cast<float>(j) * 0.001f;
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
    // neighbour. The GPU computes L2 via the ||x||^2 + ||y||^2 - 2*x.y
    // expansion, so the self-distance is a tiny rounding value rather than
    // exactly 0 (unlike the exact CPU Flat index) -- allow a small tolerance.
    for (int i = 0; i < nq; i++) {
        EXPECT_EQ(labels[i * k], static_cast<idx_t>(i));
        EXPECT_NEAR(distances[i * k], 0.0f, 1e-3f);
    }

    faiss_Index_free(index);
    faiss_GpuClonerOptions_free(options);
    faiss_Index_free(cpu_index);
    faiss_StandardGpuResources_free(res);
}
