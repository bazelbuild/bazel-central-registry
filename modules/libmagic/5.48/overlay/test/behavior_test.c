#include <magic.h>
#include <locale.h>
#ifdef __APPLE__
#include <xlocale.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <wctype.h>
#include "compressed.h"

#define CHECK(condition) do { if (!(condition)) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, #condition); \
    exit(1); \
} } while (0)

static void expect_mime(const char *actual, const char *expected, const char *what) {
    if (actual == NULL || strcmp(actual, expected) != 0) {
        fprintf(stderr, "%s: %s, expected %s\n", what, actual ? actual : "(null)", expected);
        exit(1);
    }
}

static magic_t detector(const char *database, int flags) {
    magic_t cookie = magic_open(flags | MAGIC_ERROR);
    CHECK(cookie != NULL);
    if (magic_load(cookie, database) != 0) {
        fprintf(stderr, "magic_load(%s): %s\n", database, magic_error(cookie));
        exit(1);
    }
    return cookie;
}

/* USE_C_LOCALE (src/file.h:527): libmagic compiles its regexes in the C locale through
   uselocale and leaves the caller's thread locale as it was. Without it the caller's
   UTF-8 locale reaches regcomp, and U+00E9 matches [[:alpha:]]. */
static void regex_ignores_caller_locale(const char *rules) {
    FILE *stream = fopen(rules, "w");
    CHECK(stream != NULL);
    CHECK(fputs("0 regex =^[[:alpha:]]+ regex match\n!:mime application/x-regex-match\n",
                stream) >= 0);
    CHECK(fclose(stream) == 0);
    locale_t utf8 = newlocale(LC_ALL_MASK, "C.UTF-8", (locale_t)0);
    if (utf8 == (locale_t)0)
        utf8 = newlocale(LC_ALL_MASK, "en_US.UTF-8", (locale_t)0);
    CHECK(utf8 != (locale_t)0);
    locale_t previous = uselocale(utf8);
    /* Controls: the caller's locale does count U+00E9 as alphabetic, and the rule does
       match plain ASCII, so the non-match below is libmagic's doing. */
    CHECK(iswalpha(L'\u00e9'));
    magic_t cookie = detector(rules, MAGIC_MIME_TYPE);
    expect_mime(magic_buffer(cookie, "Alphabet\n", 9), "application/x-regex-match",
                "ASCII under a UTF-8 caller locale");
    expect_mime(magic_buffer(cookie, "\xc3\xa9\n", 3), "text/plain",
                "U+00E9 under a UTF-8 caller locale");
    CHECK(uselocale((locale_t)0) == utf8);
    magic_close(cookie);
    uselocale(previous);
    freelocale(utf8);
}

/* An enabled codec decompresses inside the library; a disabled one does not produce the
   text. */
static void compressed(const char *database, const unsigned char *bytes, size_t size,
                       int enabled, const char *name) {
    magic_t cookie = detector(database, MAGIC_COMPRESS | MAGIC_MIME_TYPE);
    const char *result = magic_buffer(cookie, bytes, size);
    if (enabled)
        expect_mime(result, "text/plain", name);
    else if (result != NULL && strcmp(result, "text/plain") == 0) {
        fprintf(stderr, "%s: decompressed although its codec flag is off\n", name);
        exit(1);
    }
    magic_close(cookie);
}

int main(int argc, char **argv) {
    CHECK(argc == 2);
    const char *temporary = getenv("TEST_TMPDIR");
    CHECK(temporary != NULL);
    char rules[4096], empty[4096];
    CHECK(snprintf(rules, sizeof(rules), "%s/rules.magic", temporary) < (int)sizeof(rules));
    CHECK(snprintf(empty, sizeof(empty), "%s/no-helpers", temporary) < (int)sizeof(empty));
    /* An empty PATH, so that gzip(1) and the like cannot answer for a disabled codec. */
    CHECK(mkdir(empty, 0700) == 0);
    CHECK(setenv("PATH", empty, 1) == 0);
    regex_ignores_caller_locale(rules);
    compressed(argv[1], gzip_data, sizeof(gzip_data), EXPECT_ZLIB, "gzip");
    compressed(argv[1], bzip2_data, sizeof(bzip2_data), EXPECT_BZIP2, "bzip2");
    compressed(argv[1], xz_data, sizeof(xz_data), EXPECT_XZ, "xz");
    compressed(argv[1], zstd_data, sizeof(zstd_data), EXPECT_ZSTD, "zstd");
    return 0;
}
