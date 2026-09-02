#include <assert.h>
#include <stdlib.h>

#include <faiss/c_api/Index_c.h>
#include <faiss/c_api/index_factory_c.h>

#define FAISS_TRY(C)                                                           \
  do {                                                                         \
    assert((C) == 0);                                                          \
  } while (0)

int main() {
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
      xb[d * i + j] = (float)i + (float)j * 0.001f;
    }
  }

  FaissIndex *index = NULL;
  FAISS_TRY(faiss_index_factory(&index, d, "Flat", METRIC_L2));
  assert(faiss_Index_is_trained(index));
  FAISS_TRY(faiss_Index_add(index, nb, xb));
  assert(faiss_Index_ntotal(index) == nb);
  FAISS_TRY(faiss_Index_search(index, nq, xb, k, distances, labels));

  for (int i = 0; i < nq; i++) {
    assert(labels[i * k] == i);
    assert(distances[i * k] == 0.0f);
  }

  faiss_Index_free(index);
  free(distances);
  free(labels);
  free(xb);
  return 0;
}
