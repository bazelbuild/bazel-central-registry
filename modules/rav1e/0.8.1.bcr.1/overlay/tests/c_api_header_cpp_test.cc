#include <cstring>

#include "rav1e.h"

static_assert(RAV1E_MAJOR == 0 && RAV1E_MINOR == 8 && RAV1E_PATCH == 1,
              "unexpected rav1e header version");
static_assert(RA_CHROMA_SAMPLING_CS420 == 0 && RA_CHROMA_SAMPLING_CS422 == 1 &&
                  RA_CHROMA_SAMPLING_CS444 == 2 && RA_CHROMA_SAMPLING_CS400 == 3,
              "unexpected v_frame chroma sampling values");

int main() {
    return std::strcmp(rav1e_version_short(), "0.8.1");
}
