#include <stdlib.h>
#include <string.h>
#include <unit/test.h>
#include <lexbor/html/tokenizer.h>

TEST_BEGIN(buffer_boundary)
{
    const char *opening = "<a title=\"";
    const char *closing = "\">after-boundary</a>";
    const size_t buffer_size = 16384;

    /* &nLt; expands from five input bytes to six UTF-8 bytes. Exercise both
     * an exact buffer boundary and one spare byte, with chunked input. Run
     * with AddressSanitizer to detect the otherwise silent one-byte overwrite. */
    for (size_t shift = 0; shift < 2; shift++) {
        size_t prefix_size = strlen(opening) + buffer_size - 5 - shift;
        size_t suffix_size = 5 + 4096 + strlen(closing);
        char *prefix = malloc(prefix_size);
        char *suffix = malloc(suffix_size);
        test_ne(prefix, NULL);
        test_ne(suffix, NULL);
        memcpy(prefix, opening, strlen(opening));
        memset(prefix + strlen(opening), 'a', buffer_size - 5 - shift);
        memcpy(suffix, "&nLt;", 5);
        memset(suffix + 5, 'x', 4096);
        memcpy(suffix + 5 + 4096, closing, strlen(closing));

        lxb_html_tokenizer_t *tokenizer = lxb_html_tokenizer_create();
        test_ne(tokenizer, NULL);
        test_eq(lxb_html_tokenizer_init(tokenizer), LXB_STATUS_OK);
        test_eq(lxb_html_tokenizer_begin(tokenizer), LXB_STATUS_OK);
        test_eq(lxb_html_tokenizer_chunk(tokenizer, (const lxb_char_t *) prefix,
                                        prefix_size), LXB_STATUS_OK);
        test_eq((size_t) (tokenizer->end - tokenizer->pos), 5 + shift);
        test_eq(lxb_html_tokenizer_chunk(tokenizer, (const lxb_char_t *) suffix,
                                        suffix_size), LXB_STATUS_OK);
        test_eq(lxb_html_tokenizer_end(tokenizer), LXB_STATUS_OK);
        lxb_html_tokenizer_destroy(tokenizer);
        free(prefix);
        free(suffix);
    }
}
TEST_END

int main(int argc, const char *argv[])
{
    TEST_INIT();
    TEST_ADD(buffer_boundary);
    TEST_RUN("lexbor/html/tokenizer/named_character_reference");
    TEST_RELEASE();
}
