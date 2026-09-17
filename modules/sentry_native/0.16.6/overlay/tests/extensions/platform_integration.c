#include "sentry_integration.h"

#include <string.h>

static void
register_platform(
    void *data, sentry_scope_t *scope, const sentry_options_t *options)
{
    (void)data;
    (void)options;
    sentry_scope_set_context(scope, "bazel-platform",
        sentry_value_new_string("integration-active"));
}

sentry_integration_t *
sentry_integration_platform_new(void)
{
    sentry_integration_t *integration = sentry_malloc(sizeof(*integration));
    if (!integration) {
        return NULL;
    }
    memset(integration, 0, sizeof(*integration));
    integration->name = "bazel-platform";
    integration->register_func = register_platform;
    return integration;
}
