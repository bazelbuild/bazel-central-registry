#include <assert.h>
#include <string.h>

#include "dav1d/dav1d.h"

int main(void) {
    Dav1dContext *decoder = NULL;
    Dav1dSettings settings;
    Dav1dSequenceHeader header;
    const unsigned char invalid_obu[] = {0xff};

    dav1d_default_settings(&settings);
    settings.n_threads = 1;

    assert(dav1d_open(&decoder, &settings) == 0);
    assert(decoder != NULL);
    assert(strcmp(dav1d_version(), "1.5.4") == 0);
    assert(DAV1D_API_MAJOR(dav1d_version_api()) == DAV1D_API_VERSION_MAJOR);
    assert(dav1d_parse_sequence_header(&header, invalid_obu, sizeof(invalid_obu)) < 0);

    dav1d_close(&decoder);
    assert(decoder == NULL);
    return 0;
}
