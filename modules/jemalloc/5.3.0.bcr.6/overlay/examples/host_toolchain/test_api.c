#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define JEMALLOC_NO_DEMANGLE
#include <jemalloc/jemalloc.h>
#include <errno.h>

void print_usage(const char* prog_name) {
    printf("Usage: %s [options]\n", prog_name);
    printf("Options:\n");
    printf("  -h, --help                 Show this help message\n");
    printf("  -v, --verbose              Enable verbose output\n");
    printf("  --expect-debug             Expect jemalloc to be built with debug (config.debug)\n");
    printf("  --expect-stats-unavailable Expect stats to be unavailable (exit 0 if unavailable, 1 if not)\n");
    printf("                             By default, test expects stats to be available\n");
}

/*
 * This function explicitly tests stats functionality and optionally prints available stats
 * which can be disabled with --disable-stats
 * Returns 0 if stats are available, 1 if stats are disabled
 */
int test_stats_functionality(int verbose) {
    size_t allocated, active, resident, metadata, mapped, retained;
    size_t sz = sizeof(size_t);
    int ret;

    // Try to access stats.allocated - will fail if stats are disabled
    ret = je_mallctl("stats.allocated", &allocated, &sz, NULL, 0);

    if (ret != 0) {
        fprintf(stderr, "Stats error: Failed to get stats.allocated: %s (error code: %d)\n",
                strerror(ret), ret);
        if (ret == ENOENT) {
            fprintf(stderr, "This indicates jemalloc was compiled with --disable-stats\n");
        }
        return 1; // Stats are unavailable
    }

    // Stats are available, print them if verbose mode
    if (verbose) {
        printf("\nJemalloc Memory Stats:\n");
        printf("  Allocated: %zu bytes (%.2f MB)\n", allocated, (double)allocated / (1024 * 1024));

        // Get additional stats and print them when available
        if (je_mallctl("stats.active", &active, &sz, NULL, 0) == 0) {
            printf("  Active: %zu bytes (%.2f MB)\n", active, (double)active / (1024 * 1024));
        }

        if (je_mallctl("stats.resident", &resident, &sz, NULL, 0) == 0) {
            printf("  Resident: %zu bytes (%.2f MB)\n", resident, (double)resident / (1024 * 1024));
        }

        if (je_mallctl("stats.metadata", &metadata, &sz, NULL, 0) == 0) {
            printf("  Metadata: %zu bytes (%.2f MB)\n", metadata, (double)metadata / (1024 * 1024));
        }

        if (je_mallctl("stats.mapped", &mapped, &sz, NULL, 0) == 0) {
            printf("  Mapped: %zu bytes (%.2f MB)\n", mapped, (double)mapped / (1024 * 1024));
        }

        if (je_mallctl("stats.retained", &retained, &sz, NULL, 0) == 0) {
            printf("  Retained: %zu bytes (%.2f MB)\n", retained, (double)retained / (1024 * 1024));
        }
    }

    return 0; // Stats are available
}

int main(int argc, char** argv) {
    int expect_stats_available = 1; // Default: expect stats to be available
    int verbose = 0; // Default: non-verbose output
    int expect_debug = 0;

    // Parsed by hand rather than with getopt_long, which MSVC's C runtime lacks
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        } else if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--verbose") == 0) {
            verbose = 1;
        } else if (strcmp(argv[i], "--expect-debug") == 0) {
            expect_debug = 1;
        } else if (strcmp(argv[i], "--expect-stats-unavailable") == 0) {
            expect_stats_available = 0; // Expect stats to be unavailable
        } else {
            print_usage(argv[0]);
            return 2;
        }
    }

    // Basic check to ensure jemalloc is loaded
    const char *version;
    size_t version_size = sizeof(version);
    if (je_mallctl("version", (void*)&version, &version_size, NULL, 0) != 0) {
        fprintf(stderr, "Error: mallctl 'version' failed. Jemalloc not loaded?\n");
        return 1; // Always fail if jemalloc isn't loaded
    }

    if (verbose) {
        printf("Using jemalloc version: %s\n", version);
    }

    if (expect_debug) {
        bool debug;
        size_t debug_size = sizeof(debug);
        if (je_mallctl("config.debug", &debug, &debug_size, NULL, 0) != 0 || !debug) {
            fprintf(stderr, "Error: config.debug is not true\n");
            return 1;
        }
    }

    // Perform some allocations to have something to measure
    enum { num_allocs = 10 };  // A constant expression, as cl has no variable-length arrays
    void* ptrs[num_allocs];
    for (int i = 0; i < num_allocs; i++) {
        // Allocate blocks of increasing size
        size_t size = 1024 * (i + 1);
        ptrs[i] = malloc(size);
        if (!ptrs[i]) {
            fprintf(stderr, "malloc failed for size %zu\n", size);
            return 1;
        }
        // Write some data to ensure pages are committed
        memset(ptrs[i], i, size);
    }

    // Test stats functionality
    int stats_unavailable = test_stats_functionality(verbose);

    // Clean up allocations
    for (int i = 0; i < num_allocs; i++) {
        free(ptrs[i]);
    }

    // Determine exit code based on stats availability and expectation
    int exit_code;

    if (expect_stats_available) {
        // Expecting stats to be available
        exit_code = stats_unavailable ? 1 : 0;
    } else {
        // Expecting stats to be unavailable
        exit_code = stats_unavailable ? 0 : 1;
    }

    // Only print this if verbose mode is enabled
    if (verbose) {
        printf("\nStats %s - Test %s\n",
               stats_unavailable ? "UNAVAILABLE" : "AVAILABLE",
               exit_code == 0 ? "PASSED" : "FAILED");
    }

    return exit_code;
}