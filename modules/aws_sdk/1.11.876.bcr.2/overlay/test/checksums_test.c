#include <aws/checksums/checksums.h>
#include <aws/checksums/crc.h>
#include <aws/common/allocator.h>

#include <stdint.h>
#include <stdio.h>

int main(void) {
    // Known-answer vector from aws-checksums v0.2.10 tests/crc_test.c and
    // tests/crc64_test.c.
    const uint8_t input[] = "123456789";
    const size_t length = sizeof(input) - 1;
    int result = 0;

    aws_checksums_library_init(aws_default_allocator());

    if (aws_checksums_crc32_ex(input, length, 0) != UINT32_C(0xCBF43926)) {
        fprintf(stderr, "CRC32 mismatch\n");
        result = 1;
    }
    if (aws_checksums_crc32c_ex(input, length, 0) != UINT32_C(0xE3069283)) {
        fprintf(stderr, "CRC32C mismatch\n");
        result = 1;
    }
    if (aws_checksums_crc64nvme_ex(input, length, 0) != UINT64_C(0xAE8B14860A799888)) {
        fprintf(stderr, "CRC64NVME mismatch\n");
        result = 1;
    }

    aws_checksums_library_clean_up();
    return result;
}
