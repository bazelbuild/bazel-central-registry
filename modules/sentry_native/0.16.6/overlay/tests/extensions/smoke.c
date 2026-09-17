#include <sentry.h>

#include <string.h>

static int g_observed_platform_integration;

static sentry_value_t
before_send(sentry_value_t event, void *hint, void *user_data)
{
    (void)hint;
    (void)user_data;
    sentry_value_t contexts = sentry_value_get_by_key(event, "contexts");
    sentry_value_t platform
        = sentry_value_get_by_key(contexts, "bazel-platform");
    const char *value = sentry_value_as_string(platform);
    g_observed_platform_integration
        = value && strcmp(value, "integration-active") == 0;
    return event;
}

int
main(void)
{
    sentry_options_t *options = sentry_options_new();
    sentry_options_set_dsn(options, "https://public@example.invalid/1");
    sentry_options_set_before_send(options, before_send, NULL);
    if (sentry_init(options) != 0) {
        return 1;
    }
    sentry_capture_event(sentry_value_new_message_event(
        SENTRY_LEVEL_INFO, "extension-smoke", "custom extensions"));
    int result = sentry_close();
    return result == 0 && g_observed_platform_integration ? 0 : 2;
}
