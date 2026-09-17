#include "sentry_envelope.h"
#include "sentry_utils.h"
#include "transports/sentry_http_transport.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

int
main(void)
{
    sentry_dsn_t *dsn = sentry__dsn_new("https://foo@sentry.invalid/42");
    sentry_envelope_t *envelope = sentry__envelope_new();
    sentry__envelope_add_event(envelope,
        sentry_value_new_message_event(
            SENTRY_LEVEL_INFO, "compression-test", "compressed"));

    sentry_prepared_http_request_t *request
        = sentry__prepare_http_request(envelope, dsn, NULL, NULL);
    if (!request || request->body_len < 2
        || (uint8_t)request->body[0] != 0x1f
        || (uint8_t)request->body[1] != 0x8b) {
        return 1;
    }

    bool has_gzip_header = false;
    for (size_t i = 0; i < request->headers_len; i++) {
        if (strcmp(request->headers[i].key, "content-encoding") == 0
            && strcmp(request->headers[i].value, "gzip") == 0) {
            has_gzip_header = true;
        }
    }
    if (!has_gzip_header) {
        return 2;
    }

    z_stream stream = { 0 };
    stream.next_in = (unsigned char *)request->body;
    stream.avail_in = (unsigned int)request->body_len;
    if (inflateInit2(&stream, MAX_WBITS + 16) != Z_OK) {
        return 3;
    }

    char uncompressed[4096] = { 0 };
    stream.next_out = (unsigned char *)uncompressed;
    stream.avail_out = sizeof(uncompressed) - 1;
    int inflate_result = inflate(&stream, Z_FINISH);
    inflateEnd(&stream);
    if (inflate_result != Z_STREAM_END
        || strstr(uncompressed, "compression-test") == NULL
        || strstr(uncompressed, "compressed") == NULL) {
        return 4;
    }

    sentry__prepared_http_request_free(request);
    sentry_envelope_free(envelope);
    sentry__dsn_decref(dsn);
    return 0;
}
