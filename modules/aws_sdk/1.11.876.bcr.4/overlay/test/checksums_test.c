#include <aws/checksums/checksums.h>
#include <aws/checksums/crc.h>
#include <aws/checksums/private/crc32_priv.h>
#include <aws/checksums/private/crc64_priv.h>
#include <aws/common/allocator.h>
#include <aws/common/cpuid.h>

#include <stdint.h>
#include <stdio.h>

// Link wrapping checks dispatch deterministically, without timing thresholds.
static unsigned crc32c_sw_calls;
static unsigned crc64_sw_calls;
uint32_t __real_aws_checksums_crc32c_sw(const uint8_t *, int, uint32_t);
uint64_t __real_aws_checksums_crc64nvme_sw(const uint8_t *, int, uint64_t);

uint32_t __wrap_aws_checksums_crc32c_sw(const uint8_t *input, int length,
                                        uint32_t previous) {
  ++crc32c_sw_calls;
  return __real_aws_checksums_crc32c_sw(input, length, previous);
}

uint64_t __wrap_aws_checksums_crc64nvme_sw(const uint8_t *input, int length,
                                           uint64_t previous) {
  ++crc64_sw_calls;
  return __real_aws_checksums_crc64nvme_sw(input, length, previous);
}

#if defined(TEST_X86_V2) && defined(TEST_PCLMUL)
uint32_t aws_checksums_crc32c_intel_avx512_with_sse_fallback(const uint8_t *,
                                                             int, uint32_t);
#endif
#if defined(TEST_X86_V3) && defined(TEST_PCLMUL)
uint64_t aws_checksums_crc64nvme_intel_clmul(const uint8_t *, int, uint64_t);
#endif
#if defined(TEST_X86_V4) && defined(TEST_PCLMUL) && defined(TEST_VPCLMUL)
uint64_t aws_checksums_crc64nvme_intel_avx512(const uint8_t *, int, uint64_t);
#endif
#if defined(__aarch64__)
uint32_t aws_checksums_crc32c_armv8(const uint8_t *, int, uint32_t);
uint64_t aws_checksums_crc64nvme_arm_pmull(const uint8_t *, int, uint64_t);
#endif

#define CHECK(condition)                                                       \
  do {                                                                         \
    if (!(condition)) {                                                        \
      fprintf(stderr, "Check failed at line %d: %s\n", __LINE__, #condition);  \
      return 1;                                                                \
    }                                                                          \
  } while (0)

static int check_crc32c(uint32_t (*fn)(const uint8_t *, int, uint32_t)) {
  uint8_t data[4096 + 64];
  for (size_t i = 0; i < sizeof(data); ++i)
    data[i] = (uint8_t)(i * 197 + 101);
  const int lengths[] = {0,  1,  7,   15,  16,  17,   63,
                         64, 65, 255, 256, 257, 1000, 4096};
  for (int offset = 0; offset < 64; ++offset) {
    for (size_t i = 0; i < sizeof(lengths) / sizeof(lengths[0]); ++i) {
      CHECK(fn(data + offset, lengths[i], 0) ==
            aws_checksums_crc32c_sw(data + offset, lengths[i], 0));
    }
  }
  CHECK(fn(data + 1000, 2000, fn(data, 1000, 0)) ==
        aws_checksums_crc32c_sw(data, 3000, 0));
  return 0;
}

static int check_crc64(uint64_t (*fn)(const uint8_t *, int, uint64_t)) {
  uint8_t data[4096 + 64];
  for (size_t i = 0; i < sizeof(data); ++i)
    data[i] = (uint8_t)(i * 197 + 101);
  const int lengths[] = {0,  1,  7,   15,  16,  17,   63,
                         64, 65, 255, 256, 257, 1000, 4096};
  for (int offset = 0; offset < 64; ++offset) {
    for (size_t i = 0; i < sizeof(lengths) / sizeof(lengths[0]); ++i) {
      CHECK(fn(data + offset, lengths[i], 0) ==
            aws_checksums_crc64nvme_sw(data + offset, lengths[i], 0));
    }
  }
  CHECK(fn(data + 1000, 2000, fn(data, 1000, 0)) ==
        aws_checksums_crc64nvme_sw(data, 3000, 0));
  return 0;
}

int main(void) {
  // Known-answer vector from aws-checksums v0.2.10's own tests.
  const uint8_t input[] = "123456789";
  aws_checksums_library_init(aws_default_allocator());
  CHECK(aws_checksums_crc32_ex(input, sizeof(input) - 1, 0) ==
        UINT32_C(0xCBF43926));
  CHECK(aws_checksums_crc32c_ex(input, sizeof(input) - 1, 0) ==
        UINT32_C(0xE3069283));
  CHECK(aws_checksums_crc64nvme_ex(input, sizeof(input) - 1, 0) ==
        UINT64_C(0xAE8B14860A799888));
  CHECK(check_crc32c(aws_checksums_crc32c) == 0);
  CHECK(check_crc64(aws_checksums_crc64nvme) == 0);

  int expect_crc32c_hw = 0;
  int expect_crc64_hw = 0;
#if defined(TEST_X86_V2) && defined(TEST_PCLMUL)
  if (aws_cpu_has_feature(AWS_CPU_FEATURE_SSE_4_2) &&
      aws_cpu_has_feature(AWS_CPU_FEATURE_CLMUL)) {
    CHECK(check_crc32c(aws_checksums_crc32c_intel_avx512_with_sse_fallback) ==
          0);
    expect_crc32c_hw = 1;
  }
#endif
#if defined(TEST_X86_V3) && defined(TEST_PCLMUL)
  if (aws_cpu_has_feature(AWS_CPU_FEATURE_CLMUL) &&
      aws_cpu_has_feature(AWS_CPU_FEATURE_AVX2)) {
    CHECK(check_crc64(aws_checksums_crc64nvme_intel_clmul) == 0);
    expect_crc64_hw = 1;
  }
#endif
#if defined(TEST_X86_V4) && defined(TEST_PCLMUL) && defined(TEST_VPCLMUL)
  if (aws_cpu_has_feature(AWS_CPU_FEATURE_AVX512) &&
      aws_cpu_has_feature(AWS_CPU_FEATURE_VPCLMULQDQ)) {
    CHECK(check_crc64(aws_checksums_crc64nvme_intel_avx512) == 0);
    expect_crc64_hw = 1;
  }
#endif
#if defined(__aarch64__)
  if (aws_cpu_has_feature(AWS_CPU_FEATURE_ARM_CRC)) {
    CHECK(check_crc32c(aws_checksums_crc32c_armv8) == 0);
    expect_crc32c_hw = 1;
  }
  if (aws_cpu_has_feature(AWS_CPU_FEATURE_ARM_CRYPTO) &&
      aws_cpu_has_feature(AWS_CPU_FEATURE_ARM_PMULL)) {
    CHECK(check_crc64(aws_checksums_crc64nvme_arm_pmull) == 0);
    expect_crc64_hw = 1;
  }
#endif

  uint8_t data[4096] = {0};
  crc32c_sw_calls = crc64_sw_calls = 0;
  volatile uint32_t crc32c = aws_checksums_crc32c(data, sizeof(data), 0);
  volatile uint64_t crc64 = aws_checksums_crc64nvme(data, sizeof(data), 0);
  (void)crc32c;
  (void)crc64;
  CHECK((crc32c_sw_calls == 0) == expect_crc32c_hw);
  CHECK((crc64_sw_calls == 0) == expect_crc64_hw);
  printf("Verified CRC32C and CRC64NVME dispatch: %s, %s\n",
         expect_crc32c_hw ? "hardware" : "software",
         expect_crc64_hw ? "hardware" : "software");
  aws_checksums_library_clean_up();
  return 0;
}
