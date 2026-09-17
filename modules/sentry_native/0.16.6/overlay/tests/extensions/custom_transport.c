#include <sentry.h>

static void
discard_envelope(sentry_envelope_t *envelope, void *state)
{
    (void)state;
    sentry_envelope_free(envelope);
}

sentry_transport_t *
sentry__transport_new_default(void)
{
    return sentry_transport_new(discard_envelope);
}
