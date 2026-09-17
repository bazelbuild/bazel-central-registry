#include <sentry.h>

#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

static bool ends_with(const char *value, const char *suffix) {
  size_t value_len = strlen(value);
  size_t suffix_len = strlen(suffix);
  return value_len >= suffix_len &&
         memcmp(value + value_len - suffix_len, suffix, suffix_len) == 0;
}

static int join_path(char *output, size_t output_size, const char *directory,
                     const char *entry) {
  int length = snprintf(output, output_size, "%s/%s", directory, entry);
  return length >= 0 && (size_t)length < output_size ? 0 : -1;
}

static bool contains_bytes(const unsigned char *haystack, size_t haystack_len,
                           const unsigned char *needle, size_t needle_len) {
  if (needle_len == 0 || needle_len > haystack_len) {
    return false;
  }
  for (size_t i = 0; i <= haystack_len - needle_len; i++) {
    if (memcmp(haystack + i, needle, needle_len) == 0) {
      return true;
    }
  }
  return false;
}

static int assert_minidump(const char *path) {
  FILE *file = fopen(path, "rb");
  unsigned char signature[4] = {0};
  if (!file ||
      fread(signature, 1, sizeof(signature), file) != sizeof(signature) ||
      memcmp(signature, "MDMP", sizeof(signature)) != 0) {
    fprintf(stderr, "invalid native minidump: %s\n", path);
    if (file) {
      fclose(file);
    }
    return 1;
  }
  fclose(file);
  return 0;
}

static int assert_envelope(const char *path) {
  struct stat metadata;
  if (lstat(path, &metadata) != 0 || !S_ISREG(metadata.st_mode) ||
      metadata.st_size <= 0 || metadata.st_size > 64 * 1024 * 1024) {
    fprintf(stderr, "invalid native crash envelope: %s\n", path);
    return 1;
  }

  FILE *file = fopen(path, "rb");
  size_t length = (size_t)metadata.st_size;
  unsigned char *contents = malloc(length);
  if (!file || !contents || fread(contents, 1, length, file) != length) {
    fprintf(stderr, "could not read native crash envelope: %s\n", path);
    free(contents);
    if (file) {
      fclose(file);
    }
    return 1;
  }
  fclose(file);

  const unsigned char fatal[] = "\"level\":\"fatal\"";
  const unsigned char integration[] = "\"integrations\":[\"native\"";
  const unsigned char attachment[] = "\"attachment_type\":\"event.minidump\"";
  int result = 0;
  if (!contains_bytes(contents, length, fatal, sizeof(fatal) - 1) ||
      !contains_bytes(contents, length, integration, sizeof(integration) - 1) ||
      !contains_bytes(contents, length, attachment, sizeof(attachment) - 1) ||
      !contains_bytes(contents, length, (const unsigned char *)"MDMP", 4)) {
    fprintf(stderr,
            "native crash envelope lacks expected event/minidump data\n");
    result = 1;
  }
  free(contents);
  return result;
}

static int find_and_assert_artifacts(const char *database_path) {
  DIR *database = opendir(database_path);
  if (!database) {
    return 1;
  }

  char run_path[PATH_MAX] = {0};
  struct dirent *entry;
  while ((entry = readdir(database)) != NULL) {
    if (ends_with(entry->d_name, ".run") &&
        join_path(run_path, sizeof(run_path), database_path, entry->d_name) ==
            0) {
      break;
    }
  }
  closedir(database);
  if (!run_path[0]) {
    return 1;
  }

  char minidump_path[PATH_MAX];
  char envelope_path[PATH_MAX];
  if (join_path(minidump_path, sizeof(minidump_path), run_path,
                "__sentry-crash.dmp") != 0 ||
      join_path(envelope_path, sizeof(envelope_path), run_path,
                "__sentry-crash.envelope") != 0) {
    return 1;
  }

  struct stat minidump_metadata;
  struct stat envelope_metadata;
  if (lstat(minidump_path, &minidump_metadata) != 0 ||
      lstat(envelope_path, &envelope_metadata) != 0) {
    return 1;
  }
  return assert_minidump(minidump_path) || assert_envelope(envelope_path);
}

static void retain_crash_envelope(const sentry_envelope_t *envelope,
                                  void *user_data) {
  (void)envelope;
  (void)user_data;
}

static void run_crashing_child(const char *database_path,
                               const char *handler_path) {
  sentry_options_t *options = sentry_options_new();
  if (!options) {
    _exit(90);
  }
  sentry_options_set_database_path(options, database_path);
  sentry_options_set_handler_path(options, handler_path);
  sentry_options_set_dsn(options, "https://public@example.invalid/42");
  sentry_options_set_auto_session_tracking(options, 0);
  sentry_options_set_on_crashed_last_run(options, retain_crash_envelope, NULL);
  if (sentry_init(options) != 0) {
    _exit(91);
  }
  sentry_crash();
  _exit(92);
}

int main(int argc, char **argv) {
  if (argc != 2) {
    fprintf(stderr, "expected sentry-crash path\n");
    return 1;
  }

  const char *test_tmpdir = getenv("TEST_TMPDIR");
  if (!test_tmpdir || !test_tmpdir[0]) {
    fprintf(stderr, "TEST_TMPDIR is required\n");
    return 1;
  }

  char database_path[PATH_MAX];
  int length = snprintf(database_path, sizeof(database_path),
                        "%s/native-db-%ld", test_tmpdir, (long)getpid());
  if (length < 0 || (size_t)length >= sizeof(database_path) ||
      mkdir(database_path, 0700) != 0) {
    fprintf(stderr, "could not create native test database: %s\n",
            strerror(errno));
    return 1;
  }

  pid_t child = fork();
  if (child < 0) {
    fprintf(stderr, "fork failed: %s\n", strerror(errno));
    return 1;
  }
  if (child == 0) {
    run_crashing_child(database_path, argv[1]);
  }

  int status = 0;
  if (waitpid(child, &status, 0) != child ||
      (!WIFSIGNALED(status) && !WIFEXITED(status))) {
    fprintf(stderr, "native crash child did not terminate as expected\n");
    return 1;
  }

  struct timespec delay = {.tv_sec = 0, .tv_nsec = 50 * 1000 * 1000};
  for (int attempt = 0; attempt < 400; attempt++) {
    if (find_and_assert_artifacts(database_path) == 0) {
      return 0;
    }
    nanosleep(&delay, NULL);
  }

  fprintf(stderr, "timed out waiting for native crash artifacts in %s\n",
          database_path);
  return 1;
}
