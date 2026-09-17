#include <sentry.h>

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

int main(void) {
  const char *test_tmpdir = getenv("TEST_TMPDIR");
  if (!test_tmpdir || !test_tmpdir[0]) {
    fprintf(stderr, "TEST_TMPDIR is required\n");
    return 1;
  }

  char database_path[PATH_MAX];
  char handler_path[PATH_MAX];
  int database_length =
      snprintf(database_path, sizeof(database_path),
               "%s/invalid-handler-db-%ld", test_tmpdir, (long)getpid());
  int handler_length =
      snprintf(handler_path, sizeof(handler_path), "%s/does-not-exist-%ld",
               test_tmpdir, (long)getpid());
  if (database_length < 0 || (size_t)database_length >= sizeof(database_path) ||
      handler_length < 0 || (size_t)handler_length >= sizeof(handler_path)) {
    return 1;
  }

  sentry_options_t *options = sentry_options_new();
  if (!options) {
    return 1;
  }
  sentry_options_set_database_path(options, database_path);
  sentry_options_set_handler_path(options, handler_path);
  sentry_options_set_auto_session_tracking(options, 0);

  if (sentry_init(options) == 0) {
    fprintf(stderr, "Crashpad accepted a nonexistent handler path\n");
    sentry_close();
    return 1;
  }
  return 0;
}
