/**
 * @file test_lejp.c
 * @brief A hand authored file to test the libwebsockets bazel targets.
 */

#include <libwebsockets.h>
#include <string.h>

static int parse_ok;

static signed char cb(struct lejp_ctx *ctx, char reason) {
  if (reason == LEJPCB_COMPLETE)
    parse_ok = 1;
  return 0;
}

static const char *const paths[] = {"dummy"};

int main(void) {
  struct lejp_ctx ctx;
  const char *json = "{\"key\": \"value\", \"num\": 42, \"arr\": [1, 2, 3]}";
  int m;

  lejp_construct(&ctx, cb, NULL, paths, LWS_ARRAY_SIZE(paths));
  m = lejp_parse(&ctx, (uint8_t *)json, (int)strlen(json));
  lejp_destruct(&ctx);

  if (m < 0 && m != LEJP_CONTINUE)
    return 1;
  if (!parse_ok)
    return 2;
  return 0;
}
