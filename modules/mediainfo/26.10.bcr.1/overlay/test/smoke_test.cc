// No file I/O, so it runs on Windows CI too.

#include <cstdio>

#include "MediaInfo/MediaInfo.h"

int main() {
    MediaInfoLib::MediaInfo mi;
    const MediaInfoLib::String version = mi.Option(__T("Info_Version"));
    if (version.find(__T("26.10")) == MediaInfoLib::String::npos) {
        std::fputs("FAIL: expected a version containing 26.10, got: ", stdout);
        // String may be wide or narrow; narrow it without a locale.
        for (MediaInfoLib::String::size_type i = 0; i < version.size(); ++i) {
            const long c = static_cast<long>(version[i]);
            std::putchar(c >= 32 && c < 127 ? static_cast<char>(c) : '?');
        }
        std::putchar('\n');
        return 1;
    }
    return 0;
}
