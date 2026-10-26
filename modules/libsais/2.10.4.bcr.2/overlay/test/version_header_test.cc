// The root of the upstream archive contains a file named VERSION, which Bazel
// puts on the include path of dependents. On a case-insensitive file system,
// and with a compiler that has no separate quote-include path (MSVC), that file
// shadows the C++ standard header <version>. Including it, directly and through
// <bitset>, keeps that regression from coming back unnoticed.
#include <bitset>

#if defined(__has_include)
#if __has_include(<version>)
#include <version>
#endif
#endif

#include <cstdio>

#include "libsais.h"

int main() {
    if (std::bitset<8>(42).count() != 3) {
        fprintf(stderr, "unexpected bitset result\n");
        return 1;
    }

    const char * text = "banana";
    int32_t sa[6];

    if (libsais((const uint8_t *)text, sa, 6, 0, NULL) != 0) {
        fprintf(stderr, "libsais failed\n");
        return 1;
    }

    return sa[0] == 5 ? 0 : 1;
}
