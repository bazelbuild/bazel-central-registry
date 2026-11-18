#include <libde265/de265.h>
#include <libde265/de265-version.h>
#include "version_check.h"

#include <cassert>
#include <cstring>

int main() {
    // LIBDE265_VERSION is derived from write_file in BUILD.bazel.
    // PACKAGE_VERSION is derived from MODULE.bazel via package_info.
    // If these differ, the BUILD.bazel version is out of sync.
    assert(strcmp(LIBDE265_VERSION, PACKAGE_VERSION) == 0);

    // Error text API
    assert(de265_get_error_text(DE265_OK) != nullptr);
    assert(de265_isOK(DE265_OK));
    assert(!de265_isOK(DE265_ERROR_OUT_OF_MEMORY));

    // Decoder lifecycle
    de265_decoder_context* ctx = de265_new_decoder();
    assert(ctx != nullptr);

    // Pushing empty data should not crash
    de265_error err = de265_flush_data(ctx);
    assert(de265_isOK(err));

    // No image available without input
    const de265_image* img = de265_get_next_picture(ctx);
    assert(img == nullptr);

    err = de265_free_decoder(ctx);
    assert(de265_isOK(err));

    return 0;
}
