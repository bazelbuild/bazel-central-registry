#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

#include "tinyexr.h"

namespace {

bool RoundTripRgba() {
    const int width = 4;
    const int height = 3;
    const int components = 4;

    std::vector<float> pixels(static_cast<size_t>(width * height * components));
    for (size_t i = 0; i < pixels.size(); ++i) {
        pixels[i] = static_cast<float>(i) * 0.25f;
    }

    unsigned char* encoded = nullptr;
    const char* err = nullptr;
    // Saves as fp32 so the round trip is bit-exact.
    const int encoded_size = SaveEXRToMemory(pixels.data(), width, height, components,
                                             /*save_as_fp16=*/0, &encoded, &err);
    if (encoded_size <= 0) {
        std::fprintf(stderr, "SaveEXRToMemory failed: %s\n", err ? err : "unknown");
        FreeEXRErrorMessage(err);
        return false;
    }

    float* decoded = nullptr;
    int decoded_width = 0;
    int decoded_height = 0;
    const int rc = LoadEXRFromMemory(&decoded, &decoded_width, &decoded_height, encoded,
                                     static_cast<size_t>(encoded_size), &err);
    std::free(encoded);

    if (rc != TINYEXR_SUCCESS) {
        std::fprintf(stderr, "LoadEXRFromMemory failed: %s\n", err ? err : "unknown");
        FreeEXRErrorMessage(err);
        return false;
    }

    bool ok = decoded_width == width && decoded_height == height;
    if (ok) {
        for (size_t i = 0; i < pixels.size(); ++i) {
            if (decoded[i] != pixels[i]) {
                std::fprintf(stderr, "pixel %zu: expected %f, got %f\n", i, pixels[i], decoded[i]);
                ok = false;
                break;
            }
        }
    } else {
        std::fprintf(stderr, "size mismatch: %dx%d\n", decoded_width, decoded_height);
    }

    std::free(decoded);
    return ok;
}

} // namespace

int main() {
    if (!RoundTripRgba()) {
        return EXIT_FAILURE;
    }
    std::printf("tinyexr round trip ok\n");
    return EXIT_SUCCESS;
}
