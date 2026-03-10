#include <cstddef>
#include <cstdint>

#include "libyuv/convert.h"
#include "libyuv/convert_argb.h"

int main() {
    uint8_t y[4] = {0};
    uint8_t u[1] = {128};
    uint8_t v[1] = {128};
    uint8_t y_out[4] = {0};
    uint8_t u_out[1] = {0};
    uint8_t v_out[1] = {0};
    int width = 2;
    int height = 2;

    int copy_result = libyuv::I420Copy(
        y, width,
        u, 1,
        v, 1,
        y_out, width,
        u_out, 1,
        v_out, 1,
        width, height);

    return copy_result == 0 ? 0 : 1;
}
