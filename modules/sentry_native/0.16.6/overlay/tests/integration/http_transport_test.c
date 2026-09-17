#include <sentry.h>

#include <arpa/inet.h>
#include <ctype.h>
#include <netinet/in.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#include <zlib.h>

typedef struct {
    int listener;
    int result;
} server_state_t;

static const char *
find_header(const char *headers, const char *name)
{
    size_t name_len = strlen(name);
    for (const char *cursor = headers; *cursor; cursor++) {
        size_t i = 0;
        while (i < name_len && cursor[i]
            && tolower((unsigned char)cursor[i])
                == tolower((unsigned char)name[i])) {
            i++;
        }
        if (i == name_len) {
            return cursor;
        }
    }
    return NULL;
}

static void *
serve_one_request(void *data)
{
    server_state_t *state = data;
    int client = accept(state->listener, NULL, NULL);
    if (client < 0) {
        state->result = 10;
        return NULL;
    }

    char request[65536] = { 0 };
    size_t request_len = 0;
    size_t expected_len = 0;
    char *body = NULL;
    while (request_len < sizeof(request) - 1) {
        ssize_t received = recv(
            client, request + request_len, sizeof(request) - request_len - 1, 0);
        if (received <= 0) {
            break;
        }
        request_len += (size_t)received;
        request[request_len] = '\0';

        if (!body) {
            body = strstr(request, "\r\n\r\n");
            if (body) {
                body += 4;
                const char *content_length = find_header(request, "content-length:");
                if (!content_length) {
                    state->result = 11;
                    break;
                }
                expected_len = (size_t)strtoul(
                    content_length + strlen("content-length:"), NULL, 10);
            }
        }
        if (body && request_len >= (size_t)(body - request) + expected_len) {
            break;
        }
    }

    const char response[]
        = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
    (void)send(client, response, sizeof(response) - 1, 0);
    close(client);
    close(state->listener);

    if (state->result || !body || expected_len == 0) {
        state->result = state->result ? state->result : 12;
        return NULL;
    }

#ifdef TEST_EXPECT_COMPRESSION
    const char *encoding = find_header(request, "content-encoding:gzip");
    if (!encoding || expected_len < 2 || (unsigned char)body[0] != 0x1f
        || (unsigned char)body[1] != 0x8b) {
        fprintf(stderr,
            "compression mismatch: encoding=%d length=%zu magic=%02x%02x\n",
            encoding != NULL, expected_len, (unsigned char)body[0],
            (unsigned char)body[1]);
        fwrite(request, 1, (size_t)(body - request), stderr);
        state->result = 13;
        return NULL;
    }

    z_stream stream = { 0 };
    stream.next_in = (unsigned char *)body;
    stream.avail_in = (unsigned int)expected_len;
    char *uncompressed = calloc(1, 1024 * 1024);
    if (!uncompressed) {
        state->result = 14;
        return NULL;
    }
    stream.next_out = (unsigned char *)uncompressed;
    stream.avail_out = 1024 * 1024 - 1;
    if (inflateInit2(&stream, MAX_WBITS + 16) != Z_OK
        || inflate(&stream, Z_FINISH) != Z_STREAM_END) {
        inflateEnd(&stream);
        free(uncompressed);
        state->result = 14;
        return NULL;
    }
    inflateEnd(&stream);
    if (!strstr(uncompressed, "bazel-http-roundtrip")) {
        state->result = 15;
    }
    free(uncompressed);
#else
    if (find_header(request, "content-encoding:gzip")
        || !strstr(body, "bazel-http-roundtrip")) {
        state->result = 16;
    }
#endif
    return NULL;
}

int
main(void)
{
    int listener = socket(AF_INET, SOCK_STREAM, 0);
    if (listener < 0) {
        return 1;
    }

    struct sockaddr_in address = {
        .sin_family = AF_INET,
        .sin_addr.s_addr = htonl(INADDR_LOOPBACK),
        .sin_port = 0,
    };
    if (bind(listener, (struct sockaddr *)&address, sizeof(address)) != 0
        || listen(listener, 1) != 0) {
        return 2;
    }

    socklen_t address_len = sizeof(address);
    if (getsockname(listener, (struct sockaddr *)&address, &address_len) != 0) {
        return 3;
    }

    server_state_t state = { .listener = listener, .result = 0 };
    pthread_t server_thread;
    if (pthread_create(&server_thread, NULL, serve_one_request, &state) != 0) {
        return 4;
    }

    char dsn[128];
    snprintf(dsn, sizeof(dsn), "http://public@127.0.0.1:%u/1",
        (unsigned)ntohs(address.sin_port));
    sentry_options_t *options = sentry_options_new();
    sentry_options_set_dsn(options, dsn);
    sentry_options_set_shutdown_timeout(options, 5000);
    if (sentry_init(options) != 0) {
        return 5;
    }

    sentry_capture_event(sentry_value_new_message_event(
        SENTRY_LEVEL_INFO, "bazel-test", "bazel-http-roundtrip"));
    if (sentry_close() != 0) {
        return 6;
    }
    if (pthread_join(server_thread, NULL) != 0) {
        return 7;
    }
    return state.result;
}
