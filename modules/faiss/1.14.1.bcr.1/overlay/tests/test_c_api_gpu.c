#include <assert.h>
#include <stdlib.h>

#include <faiss/c_api/Index_c.h>
#include <faiss/c_api/gpu/DeviceUtils_c.h>
#include <faiss/c_api/gpu/GpuAutoTune_c.h>
#include <faiss/c_api/gpu/GpuClonerOptions_c.h>
#include <faiss/c_api/gpu/StandardGpuResources_c.h>
#include <faiss/c_api/index_factory_c.h>

#define FAISS_TRY(C)                                                           \
  do {                                                                         \
    assert((C) == 0);                                                          \
  } while (0)

int main() {
  int gpus = 0;
  FAISS_TRY(faiss_get_num_gpus(&gpus));
  if (gpus == 0) {
    return 0;
  }

  const int d = 16;
  const int nb = 64;
  const int nq = 5;
  const int k = 3;
  float *xb = malloc(d * nb * sizeof(float));
  idx_t *labels = malloc(k * nq * sizeof(idx_t));
  float *distances = malloc(k * nq * sizeof(float));
  assert(xb && labels && distances);

  for (int i = 0; i < nb; i++) {
    for (int j = 0; j < d; j++) {
      xb[d * i + j] = (float)i * 0.1f + (float)j * 0.001f;
    }
  }

  FaissStandardGpuResources *resources = NULL;
  FaissGpuClonerOptions *options = NULL;
  FaissIndex *cpu_index = NULL;
  FaissGpuIndex *index = NULL;
  FAISS_TRY(faiss_StandardGpuResources_new(&resources));
  FAISS_TRY(faiss_index_factory(&cpu_index, d, "Flat", METRIC_L2));
  FAISS_TRY(faiss_GpuClonerOptions_new(&options));
  FAISS_TRY(faiss_index_cpu_to_gpu_with_options(resources, 0, cpu_index,
                                                options, &index));
  assert(faiss_Index_is_trained(index));
  FAISS_TRY(faiss_Index_add(index, nb, xb));
  assert(faiss_Index_ntotal(index) == nb);
  FAISS_TRY(faiss_Index_search(index, nq, xb, k, distances, labels));

  for (int i = 0; i < nq; i++) {
    assert(labels[i * k] == i);
  }

  faiss_Index_free(index);
  faiss_GpuClonerOptions_free(options);
  faiss_Index_free(cpu_index);
  faiss_StandardGpuResources_free(resources);
  free(distances);
  free(labels);
  free(xb);
  return 0;
}
