#include <stdbool.h>
#include <stdint.h>

typedef struct sentry_path_s sentry_path_t;

bool
sentry__screenshot_capture(const sentry_path_t *path, uint32_t pid)
{
    (void)path;
    (void)pid;
    return false;
}
