#include <sentry.h>

int main(int argc, char **argv)
{
    sentry_options_t *options = sentry_options_new();
    if (argc > 1) {
        sentry_options_set_handler_path(options, argv[1]);
    }
    sentry_options_set_dsn(options, "https://public@example.invalid/1");
    if (sentry_init(options) != 0) {
        return 1;
    }

    sentry_capture_event(sentry_value_new_message_event(
        SENTRY_LEVEL_INFO, "bazel-smoke", "hello from Bazel"));
    return sentry_close();
}
