#include <string.h>
#include "libslirp.h"

int main(void)
{
    return strcmp(slirp_version_string(), "4.9.5") != 0;
}
