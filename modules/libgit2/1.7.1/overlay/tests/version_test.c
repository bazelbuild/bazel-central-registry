#include <git2.h>
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int major, minor, rev, features, rc;

    rc = git_libgit2_init();
    if (rc < 0) {
        fprintf(stderr, "git_libgit2_init failed: %d\n", rc);
        return 1;
    }

    rc = git_libgit2_version(&major, &minor, &rev);
    if (rc != 0) {
        fprintf(stderr, "git_libgit2_version failed: %d\n", rc);
        return 1;
    }
    if (major < 1) {
        fprintf(stderr, "unexpected major version: %d\n", major);
        return 1;
    }
    printf("libgit2 %d.%d.%d\n", major, minor, rev);

    features = git_libgit2_features();
    if (!(features & GIT_FEATURE_THREADS)) {
        fprintf(stderr, "expected GIT_FEATURE_THREADS\n");
        return 1;
    }

    rc = git_libgit2_shutdown();
    if (rc != 0) {
        fprintf(stderr, "git_libgit2_shutdown failed: %d\n", rc);
        return 1;
    }

    return 0;
}
