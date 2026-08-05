// Stages the .icc corpus into TEST_TMPDIR and runs upstream's testcms there.
// The suite reads and writes .icc files in its CWD, and TEST_TMPDIR is the
// one directory a Bazel test may write to. Paths are anchored at TEST_SRCDIR
// so they resolve whether lcms2 is the root module or an external dependency
// (BCR presubmit runs a module's test targets from an anonymous consumer
// module, so CWD-relative runfiles paths do not work there). argv: the
// testcms rlocation path, then the corpus rlocation paths. POSIX-only by
// design: CI runs this on the unix axis; on Windows it compiles as a stub.
#if defined(_WIN32)

#include <stdio.h>

int main(void) {
    fprintf(stderr, "testcms wrapper is POSIX-only\n");
    return 1;
}

#else

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static int copy_file(const char *src, const char *dst) {
    FILE *in = fopen(src, "rb");
    if (in == NULL) {
        fprintf(stderr, "open %s: %s\n", src, strerror(errno));
        return -1;
    }
    FILE *out = fopen(dst, "wb");
    if (out == NULL) {
        fprintf(stderr, "open %s: %s\n", dst, strerror(errno));
        fclose(in);
        return -1;
    }
    char buf[65536];
    size_t n;
    while ((n = fread(buf, 1, sizeof buf, in)) > 0) {
        if (fwrite(buf, 1, n, out) != n) {
            fprintf(stderr, "write %s: %s\n", dst, strerror(errno));
            fclose(in);
            fclose(out);
            return -1;
        }
    }
    fclose(in);
    if (fclose(out) != 0) {
        fprintf(stderr, "close %s: %s\n", dst, strerror(errno));
        return -1;
    }
    return 0;
}

int main(int argc, char *argv[]) {
    const char *srcdir = getenv("TEST_SRCDIR");
    const char *tmpdir = getenv("TEST_TMPDIR");
    if (srcdir == NULL || tmpdir == NULL || argc < 2) {
        fprintf(stderr, "usage (under bazel test): run_testcms <testcms rlocationpath> <icc rlocationpaths...>\n");
        return 1;
    }

    char workdir[4096];
    snprintf(workdir, sizeof workdir, "%s/testbed", tmpdir);
    if (mkdir(workdir, 0755) != 0 && errno != EEXIST) {
        fprintf(stderr, "mkdir %s: %s\n", workdir, strerror(errno));
        return 1;
    }

    char bin[4096];
    snprintf(bin, sizeof bin, "%s/%s", srcdir, argv[1]);

    for (int i = 2; i < argc; i++) {
        char src[4096], dst[4096];
        snprintf(src, sizeof src, "%s/%s", srcdir, argv[i]);
        const char *slash = strrchr(argv[i], '/');
        snprintf(dst, sizeof dst, "%s/%s", workdir, slash != NULL ? slash + 1 : argv[i]);
        if (copy_file(src, dst) != 0) {
            return 1;
        }
    }

    if (chdir(workdir) != 0) {
        fprintf(stderr, "chdir %s: %s\n", workdir, strerror(errno));
        return 1;
    }
    execl(bin, bin, (char *)NULL);
    fprintf(stderr, "exec %s: %s\n", bin, strerror(errno));
    return 1;
}

#endif
