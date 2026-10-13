#include <libheif/heif.h>
#include <libheif/heif_version.h>
#include "version_check.h"

#include <cassert>
#include <cstring>

int main() {
    // LIBHEIF_VERSION is derived from _VERSION_* constants in BUILD.bazel.
    // PACKAGE_VERSION is derived from MODULE.bazel via package_info.
    // If these differ, the BUILD.bazel constants are out of sync.
    assert(strcmp(LIBHEIF_VERSION, PACKAGE_VERSION) == 0);

    // Library initialization
    heif_error err = heif_init(nullptr);
    assert(err.code == heif_error_Ok);

    // Context lifecycle
    heif_context* ctx = heif_context_alloc();
    assert(ctx != nullptr);

    // No images in empty context
    int count = heif_context_get_number_of_top_level_images(ctx);
    assert(count == 0);

    heif_context_free(ctx);
    heif_deinit();

    return 0;
}
