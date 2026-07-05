#include <string.h>

#include <zip.h>

int
main(void) {
    return strcmp(zip_libzip_version(), "1.11.4") == 0 ? 0 : 1;
}
