// Smoke test for the @mediainfo module: a downstream consumer compiles against
// MediaInfo/MediaInfo.h, links the library plus its ZenLib/zlib deps, and calls
// into it at run time. Asserting the exact version catches wrong-version archive
// resolution, broken module wiring or linkage, and a wide-Ztring ABI mismatch
// with ZenLib (a mismatch fails at link time or yields garbage here). No file
// I/O on purpose: this must also run on Windows CI, where a materialized
// runfiles tree is not guaranteed.

#include <cstdio>

#include "MediaInfo/MediaInfo.h"

int main() {
    MediaInfoLib::MediaInfo mi;
    const MediaInfoLib::String version = mi.Option(__T("Info_Version"));
    if (version.find(__T("26.05")) == MediaInfoLib::String::npos) {
        std::fputs("FAIL: expected a version containing 26.05, got: ", stdout);
        // Char-by-char narrowing keeps this printable whether String is wide
        // (UNICODE, the ABI zenlib propagates) or narrow, with no locale use.
        for (MediaInfoLib::String::size_type i = 0; i < version.size(); ++i) {
            const long c = static_cast<long>(version[i]);
            std::putchar(c >= 32 && c < 127 ? static_cast<char>(c) : '?');
        }
        std::putchar('\n');
        return 1;
    }
    return 0;
}
