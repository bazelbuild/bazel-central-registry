#include "crash_artifact_fixture.h"

#include <sentry.h>

#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#ifndef PATH_MAX
#    define PATH_MAX 4096
#endif

static bool
ends_with(const char *value, const char *suffix)
{
    size_t value_len = strlen(value);
    size_t suffix_len = strlen(suffix);
    return value_len >= suffix_len
        && memcmp(value + value_len - suffix_len, suffix, suffix_len) == 0;
}

static int
join_path(
    char *output, size_t output_size, const char *directory, const char *entry)
{
    int length = snprintf(output, output_size, "%s/%s", directory, entry);
    return length >= 0 && (size_t)length < output_size ? 0 : -1;
}

static bool
contains_bytes(const unsigned char *haystack, size_t haystack_len,
    const unsigned char *needle, size_t needle_len)
{
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

static int
assert_envelope(const char *path)
{
    struct stat metadata;
    if (lstat(path, &metadata) != 0 || !S_ISREG(metadata.st_mode)
        || metadata.st_size <= 0 || metadata.st_size > 64 * 1024 * 1024) {
        fprintf(stderr, "invalid crash envelope: %s\n", path);
        return 1;
    }

    FILE *file = fopen(path, "rb");
    if (!file) {
        fprintf(stderr, "could not open crash envelope %s: %s\n", path,
            strerror(errno));
        return 1;
    }

    size_t length = (size_t)metadata.st_size;
    unsigned char *contents = malloc(length);
    if (!contents || fread(contents, 1, length, file) != length) {
        fprintf(stderr, "could not read crash envelope: %s\n", path);
        free(contents);
        fclose(file);
        return 1;
    }
    fclose(file);

#define ASSERT_CONTAINS(literal, description)                                  \
    do {                                                                       \
        const unsigned char needle[] = literal;                                \
        if (!contains_bytes(contents, length, needle, sizeof(needle) - 1)) {   \
            fprintf(                                                           \
                stderr, "crash envelope missing %s: %s\n", description, path); \
            free(contents);                                                    \
            return 1;                                                          \
        }                                                                      \
    } while (0)

    ASSERT_CONTAINS(
        "\"integrations\":[\"breakpad\"", "Breakpad integration metadata");
    ASSERT_CONTAINS("\"level\":\"fatal\"", "fatal event");
    ASSERT_CONTAINS(
        "\"attachment_type\":\"event.minidump\"", "minidump attachment header");
    ASSERT_CONTAINS("MDMP", "minidump payload magic");

#undef ASSERT_CONTAINS

    free(contents);
    return 0;
}

static int
find_run_artifacts(const char *database_path)
{
    DIR *database = opendir(database_path);
    if (!database) {
        fprintf(stderr, "could not open database %s: %s\n", database_path,
            strerror(errno));
        return 1;
    }

    char run_path[PATH_MAX] = { 0 };
    size_t run_count = 0;
    struct dirent *entry;
    while ((entry = readdir(database)) != NULL) {
        if (!ends_with(entry->d_name, ".run")) {
            continue;
        }
        char candidate[PATH_MAX];
        struct stat metadata;
        if (join_path(
                candidate, sizeof(candidate), database_path, entry->d_name)
                != 0
            || lstat(candidate, &metadata) != 0 || !S_ISDIR(metadata.st_mode)) {
            continue;
        }
        run_count++;
        if (run_count == 1) {
            memcpy(run_path, candidate, strlen(candidate) + 1);
        }
    }
    closedir(database);

    if (run_count != 1) {
        fprintf(
            stderr, "expected one crash run directory, found %zu\n", run_count);
        return 1;
    }

    DIR *run = opendir(run_path);
    if (!run) {
        fprintf(stderr, "could not open run directory %s: %s\n", run_path,
            strerror(errno));
        return 1;
    }

    char envelope_path[PATH_MAX] = { 0 };
    char envelope_stem[NAME_MAX + 1] = { 0 };
    char marker_stem[NAME_MAX + 1] = { 0 };
    size_t envelope_count = 0;
    size_t marker_count = 0;
    while ((entry = readdir(run)) != NULL) {
        char candidate[PATH_MAX];
        struct stat metadata;
        if (join_path(candidate, sizeof(candidate), run_path, entry->d_name)
                != 0
            || lstat(candidate, &metadata) != 0 || !S_ISREG(metadata.st_mode)) {
            continue;
        }
        if (ends_with(entry->d_name, ".envelope")) {
            size_t stem_len = strlen(entry->d_name) - strlen(".envelope");
            envelope_count++;
            if (envelope_count == 1 && stem_len <= NAME_MAX) {
                memcpy(envelope_path, candidate, strlen(candidate) + 1);
                memcpy(envelope_stem, entry->d_name, stem_len);
                envelope_stem[stem_len] = '\0';
            }
        } else if (ends_with(entry->d_name, ".crash")) {
            size_t stem_len = strlen(entry->d_name) - strlen(".crash");
            marker_count++;
            if (marker_count == 1 && stem_len <= NAME_MAX) {
                memcpy(marker_stem, entry->d_name, stem_len);
                marker_stem[stem_len] = '\0';
            }
        }
    }
    closedir(run);

    if (envelope_count != 1 || marker_count != 1
        || strcmp(envelope_stem, marker_stem) != 0) {
        fprintf(stderr,
            "expected one matching envelope/crash marker pair; "
            "envelopes=%zu markers=%zu envelope=%s marker=%s\n",
            envelope_count, marker_count, envelope_stem, marker_stem);
        return 1;
    }

    return assert_envelope(envelope_path);
}

static int
assert_last_crash(const char *database_path)
{
    char path[PATH_MAX];
    struct stat metadata;
    if (join_path(path, sizeof(path), database_path, "last_crash") != 0
        || lstat(path, &metadata) != 0 || !S_ISREG(metadata.st_mode)
        || metadata.st_size <= 0) {
        fprintf(stderr, "missing or empty last_crash marker in %s\n",
            database_path);
        return 1;
    }
    return 0;
}

static void
run_crashing_child(const char *database_path)
{
    sentry_options_t *options = sentry_options_new();
    if (!options) {
        _exit(90);
    }
    sentry_options_set_database_path(options, database_path);
    sentry_options_set_auto_session_tracking(options, 0);
    if (sentry_init(options) != 0) {
        _exit(91);
    }

    sentry_crash();
    _exit(92);
}

int
sentry_breakpad_crash_artifact_test(void)
{
    const char *test_tmpdir = getenv("TEST_TMPDIR");
    if (!test_tmpdir || !test_tmpdir[0]) {
        fprintf(stderr, "TEST_TMPDIR is required\n");
        return 1;
    }

    char database_path[PATH_MAX] = { 0 };
    int length = snprintf(database_path, sizeof(database_path),
        "%s/breakpad-db-%ld", test_tmpdir, (long)getpid());
    if (length < 0 || (size_t)length >= sizeof(database_path)) {
        fprintf(stderr, "isolated database path exceeds PATH_MAX\n");
        return 1;
    }
    if (mkdir(database_path, 0700) != 0) {
        fprintf(stderr, "could not create isolated database %s: %s\n",
            database_path, strerror(errno));
        return 1;
    }

    pid_t child = fork();
    if (child < 0) {
        fprintf(stderr, "fork failed: %s\n", strerror(errno));
        return 1;
    }
    if (child == 0) {
        run_crashing_child(database_path);
    }

    int status = 0;
    if (waitpid(child, &status, 0) != child) {
        fprintf(stderr, "waitpid failed: %s\n", strerror(errno));
        return 1;
    }
    // Breakpad re-raises the crash signal on Linux. Its macOS Mach exception
    // handler terminates with exit code 1 after writing the report, matching
    // the pinned upstream integration tests' nonzero-exit contract.
    bool expected_crash_exit = WIFSIGNALED(status)
        || (WIFEXITED(status) && WEXITSTATUS(status) == 1);
    if (!expected_crash_exit) {
        fprintf(stderr,
            "child did not terminate through Breakpad (status %d)\n",
            status);
        return 1;
    }

    if (assert_last_crash(database_path) != 0) {
        return 1;
    }
    return find_run_artifacts(database_path);
}
