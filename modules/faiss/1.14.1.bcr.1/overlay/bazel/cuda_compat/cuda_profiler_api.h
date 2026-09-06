// Compatibility shim for <cuda_profiler_api.h>.
//
// The CUDA 13.x cudart redistributable (as fetched by rules_cuda's hermetic
// toolkit) ships cudaProfilerTypedefs.h but omits the <cuda_profiler_api.h>
// convenience wrapper that faiss/gpu/utils/DeviceUtils.cu includes. This shim
// provides the two entry points faiss uses; they are exported by libcudart on
// every supported CUDA version, so this is safe whether or not the toolkit
// also ships the real header (identical declarations, first match wins).
#ifndef FAISS_BAZEL_CUDA_COMPAT_CUDA_PROFILER_API_H_
#define FAISS_BAZEL_CUDA_COMPAT_CUDA_PROFILER_API_H_

#include <driver_types.h>

#if defined(__cplusplus)
extern "C" {
#endif

extern __host__ cudaError_t CUDARTAPI cudaProfilerStart(void);
extern __host__ cudaError_t CUDARTAPI cudaProfilerStop(void);

#if defined(__cplusplus)
}
#endif

#endif  // FAISS_BAZEL_CUDA_COMPAT_CUDA_PROFILER_API_H_
