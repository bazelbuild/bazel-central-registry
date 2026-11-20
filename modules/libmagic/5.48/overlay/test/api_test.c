#include <magic.h>
#include <stdio.h>
#include <string.h>

/* HAVE_CONFIG_H would arrive if the overlay declared its local_defines as defines;
   HAVE_MMAP and VERSION if the rendered config.h became reachable from a consumer's
   include path; MAGIC from upstream's AM_CPPFLAGS (src/Makefile.am:7), which this
   overlay keeps local to its own compiles. */
#if defined(HAVE_CONFIG_H) || defined(HAVE_MMAP) || defined(VERSION) || defined(MAGIC)
#error "private configuration leaked into the public compilation context"
#endif

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: api_test <magic database>\n");
        return 2;
    }
    magic_t cookie = magic_open(MAGIC_MIME_TYPE | MAGIC_ERROR);
    if (cookie == NULL) {
        perror("magic_open");
        return 1;
    }
    if (magic_load(cookie, argv[1]) != 0) {
        fprintf(stderr, "magic_load(%s): %s\n", argv[1], magic_error(cookie));
        return 1;
    }
    const char *mime = magic_buffer(cookie, "hello world\n", 12);
    if (mime == NULL || strcmp(mime, "text/plain") != 0) {
        fprintf(stderr, "a plain text buffer was classified as %s, expected text/plain\n",
                mime ? mime : magic_error(cookie));
        return 1;
    }
    magic_close(cookie);
    return 0;
}
