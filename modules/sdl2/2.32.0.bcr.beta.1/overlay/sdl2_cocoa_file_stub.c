/*
 * SDL's mac bundle helper is implemented in Objective-C upstream.
 * This Bazel packaging pass does not enable Cocoa app integration,
 * so keep plain file-open fallback behavior on macOS.
 */

#include <stdio.h>

#ifdef __APPLE__
FILE *SDL_OpenFPFromBundleOrFallback(const char *file, const char *mode)
{
    return fopen(file, mode);
}
#endif
