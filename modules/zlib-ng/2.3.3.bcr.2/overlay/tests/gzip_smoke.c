#include <stdint.h>
#include <stdio.h>
#include <string.h>

#if defined(ZLIB_NG_NATIVE)
#include <zlib-ng.h>
typedef zng_stream gzip_stream;
#define gzip_deflate_init(stream) \
    zng_deflateInit2(stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY)
#define gzip_deflate(stream, flush) zng_deflate(stream, flush)
#define gzip_deflate_end(stream) zng_deflateEnd(stream)
#define gzip_inflate_init(stream) zng_inflateInit2(stream, 15 + 16)
#define gzip_inflate(stream, flush) zng_inflate(stream, flush)
#define gzip_inflate_end(stream) zng_inflateEnd(stream)
#define gzip_crc32(checksum, data, length) zng_crc32(checksum, data, length)
#else
#include <zlib.h>
typedef z_stream gzip_stream;
#define gzip_deflate_init(stream) \
    deflateInit2(stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY)
#define gzip_deflate(stream, flush) deflate(stream, flush)
#define gzip_deflate_end(stream) deflateEnd(stream)
#define gzip_inflate_init(stream) inflateInit2(stream, 15 + 16)
#define gzip_inflate(stream, flush) inflate(stream, flush)
#define gzip_inflate_end(stream) inflateEnd(stream)
#define gzip_crc32(checksum, data, length) crc32(checksum, data, length)
#endif

static int decompress(const unsigned char *compressed, size_t length) {
    static const unsigned char expected[] = "123456789";
    unsigned char output[sizeof(expected)] = {0};
    gzip_stream stream = {0};
    int result;

    stream.next_in = (unsigned char *)compressed;
    stream.avail_in = (unsigned int)length;
    stream.next_out = output;
    stream.avail_out = sizeof(output);

    if (gzip_inflate_init(&stream) != Z_OK)
        return 1;
    result = gzip_inflate(&stream, Z_FINISH);
    gzip_inflate_end(&stream);
    if (result != Z_STREAM_END)
        return 1;
    if (stream.total_out != sizeof(expected) - 1)
        return 1;
    if (memcmp(output, expected, sizeof(expected) - 1) != 0)
        return 1;
    return 0;
}

static int roundtrip_large_input(void) {
    unsigned char input[4096];
    unsigned char compressed[8192];
    unsigned char output[4096];
    gzip_stream encoder = {0};
    gzip_stream decoder = {0};
    int result;

    for (size_t index = 0; index < sizeof(input); ++index)
        input[index] = (unsigned char)(index * 31U);

    encoder.next_in = input;
    encoder.avail_in = sizeof(input);
    encoder.next_out = compressed;
    encoder.avail_out = sizeof(compressed);
    if (gzip_deflate_init(&encoder) != Z_OK)
        return 1;
    result = gzip_deflate(&encoder, Z_FINISH);
    gzip_deflate_end(&encoder);
    if (result != Z_STREAM_END)
        return 1;

    decoder.next_in = compressed;
    decoder.avail_in = (unsigned int)encoder.total_out;
    decoder.next_out = output;
    decoder.avail_out = sizeof(output);
    if (gzip_inflate_init(&decoder) != Z_OK)
        return 1;
    result = gzip_inflate(&decoder, Z_FINISH);
    gzip_inflate_end(&decoder);
    if (result != Z_STREAM_END)
        return 1;
    return decoder.total_out != sizeof(input) || memcmp(input, output, sizeof(input)) != 0;
}

int main(void) {
    static const unsigned char compressed[] = {
        31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 51, 52, 50, 54, 49,
        53, 51, 183, 176, 4, 0, 38, 57, 244, 203, 9, 0, 0, 0,
    };
    static const unsigned char expected[] = "123456789";
    unsigned char corrupted[sizeof(compressed)];

    if (gzip_crc32(0, expected, sizeof(expected) - 1) != 0xcbf43926U) {
        fputs("CRC-32 validation failed\n", stderr);
        return 1;
    }
    if (decompress(compressed, sizeof(compressed)) != 0) {
        fputs("gzip decompression failed\n", stderr);
        return 1;
    }
    if (roundtrip_large_input() != 0) {
        fputs("large gzip round trip failed\n", stderr);
        return 1;
    }

    memcpy(corrupted, compressed, sizeof(corrupted));
    corrupted[sizeof(corrupted) - 8] ^= 1;
    if (decompress(corrupted, sizeof(corrupted)) == 0) {
        fputs("corrupted gzip trailer was accepted\n", stderr);
        return 1;
    }
    return 0;
}
