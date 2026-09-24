// Stages the .icc corpus into TEST_TMPDIR and runs upstream's testcms there:
// the suite reads and writes .icc files in its CWD, and TEST_TMPDIR is the
// one directory a Bazel test may write to. The runfiles library resolves
// paths whether lcms2 is the root module or an external dependency (BCR
// presubmit runs test targets from an anonymous consumer module) and on
// Windows, where no runfiles tree is materialized, only the manifest.
// argv: the testcms rlocation path, then the corpus rlocation paths.
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <memory>
#include <string>

#include "tools/cpp/runfiles/runfiles.h"

#ifdef _WIN32
#include <direct.h>
#include <process.h>
#else
#include <sys/stat.h>
#include <unistd.h>
#endif

using bazel::tools::cpp::runfiles::Runfiles;

static int copy_file(const std::string &src, const std::string &dst) {
    FILE *in = fopen(src.c_str(), "rb");
    if (in == NULL) {
        fprintf(stderr, "open %s failed\n", src.c_str());
        return -1;
    }
    FILE *out = fopen(dst.c_str(), "wb");
    if (out == NULL) {
        fprintf(stderr, "open %s failed\n", dst.c_str());
        fclose(in);
        return -1;
    }
    char buf[65536];
    size_t n;
    while ((n = fread(buf, 1, sizeof buf, in)) > 0) {
        if (fwrite(buf, 1, n, out) != n) {
            fprintf(stderr, "write %s failed\n", dst.c_str());
            fclose(in);
            fclose(out);
            return -1;
        }
    }
    fclose(in);
    if (fclose(out) != 0) {
        fprintf(stderr, "close %s failed\n", dst.c_str());
        return -1;
    }
    return 0;
}

int main(int argc, char *argv[]) {
    const char *tmpdir = getenv("TEST_TMPDIR");
    if (tmpdir == NULL || argc < 2) {
        fprintf(stderr, "usage (under bazel test): run_testcms <testcms rlocationpath> <icc rlocationpaths...>\n");
        return 1;
    }

    std::string error;
    std::unique_ptr<Runfiles> runfiles(Runfiles::Create(argv[0], &error));
    if (runfiles == NULL) {
        fprintf(stderr, "runfiles: %s\n", error.c_str());
        return 1;
    }

    std::string workdir = std::string(tmpdir) + "/testbed";
#ifdef _WIN32
    if (_mkdir(workdir.c_str()) != 0 && errno != EEXIST) {
#else
    if (mkdir(workdir.c_str(), 0755) != 0 && errno != EEXIST) {
#endif
        fprintf(stderr, "mkdir %s failed\n", workdir.c_str());
        return 1;
    }

    std::string bin = runfiles->Rlocation(argv[1]);
    if (bin.empty()) {
        fprintf(stderr, "rlocation %s failed\n", argv[1]);
        return 1;
    }

    for (int i = 2; i < argc; i++) {
        std::string src = runfiles->Rlocation(argv[i]);
        if (src.empty()) {
            fprintf(stderr, "rlocation %s failed\n", argv[i]);
            return 1;
        }
        const char *slash = strrchr(argv[i], '/');
        std::string dst = workdir + "/" + (slash != NULL ? slash + 1 : argv[i]);
        if (copy_file(src, dst) != 0) {
            return 1;
        }
    }

#ifdef _WIN32
    if (_chdir(workdir.c_str()) != 0) {
#else
    if (chdir(workdir.c_str()) != 0) {
#endif
        fprintf(stderr, "chdir %s failed\n", workdir.c_str());
        return 1;
    }

#ifdef _WIN32
    const char *spawn_argv[] = {bin.c_str(), NULL};
    intptr_t rc = _spawnv(_P_WAIT, bin.c_str(), spawn_argv);
    if (rc == -1) {
        fprintf(stderr, "spawn %s failed\n", bin.c_str());
        return 1;
    }
    return (int)rc;
#else
    execl(bin.c_str(), bin.c_str(), (char *)NULL);
    fprintf(stderr, "exec %s: %s\n", bin.c_str(), strerror(errno));
    return 1;
#endif
}
