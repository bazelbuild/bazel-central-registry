// Smoke test for tclsh: locate the binary via runfiles, invoke it with a
// small script, and verify it evaluates to the expected value.

#include "rules_cc/cc/runfiles/runfiles.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

#ifdef _WIN32
#define popen _popen
#define pclose _pclose
#endif

using rules_cc::cc::runfiles::Runfiles;

static int failures = 0;

static void check(const char *label, bool condition) {
    if (condition) {
        std::fprintf(stdout, "  PASS: %s\n", label);
    } else {
        std::fprintf(stderr, "  FAIL: %s\n", label);
        ++failures;
    }
}

static std::string run_capture(const std::string &cmd, int *exit_status) {
    FILE *pipe = popen(cmd.c_str(), "r");
    if (!pipe) {
        *exit_status = -1;
        return "";
    }
    std::string output;
    char buf[512];
    while (std::fgets(buf, sizeof(buf), pipe)) {
        output += buf;
    }
    *exit_status = pclose(pipe);
    return output;
}

static std::string quote(const std::string &s) {
#ifdef _WIN32
    // Paths from Bazel runfiles don't contain spaces; skip quoting to
    // avoid cmd.exe's double-quote parsing.
    return s;
#else
    return "\"" + s + "\"";
#endif
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        std::fprintf(stderr, "usage: %s <tclsh_rlocationpath>\n", argv[0]);
        return 1;
    }

    std::string error;
    Runfiles *r = Runfiles::Create(argv[0], &error);
    if (!r) {
        std::fprintf(stderr, "Runfiles error: %s\n", error.c_str());
        return 1;
    }

    std::string tclsh = r->Rlocation(argv[1]);
    if (tclsh.empty()) {
        std::fprintf(stderr, "cannot resolve tclsh rlocation: %s\n", argv[1]);
        delete r;
        return 1;
    }
    std::fprintf(stdout, "tclsh: %s\n", tclsh.c_str());

    // 1) Version banner.  `tclsh << "puts [info patchlevel]"` prints a
    // dotted version string and exits 0.
    {
        std::string cmd =
            "echo puts [info patchlevel] | " + quote(tclsh);
        int status;
        std::string out = run_capture(cmd, &status);
        std::fprintf(stdout, "\n[version] %s\nexit=%d out=%s",
                     cmd.c_str(), status, out.c_str());
        check("version exits 0", status == 0);
        check("version starts with 9.", out.rfind("9.", 0) == 0);
    }

    // 2) Arithmetic: proves the interpreter can parse, compile, and
    // evaluate a script.  6 * 7 == 42.
    {
        std::string cmd =
            "echo puts [expr {6*7}] | " + quote(tclsh);
        int status;
        std::string out = run_capture(cmd, &status);
        std::fprintf(stdout, "\n[expr] %s\nexit=%d out=%s",
                     cmd.c_str(), status, out.c_str());
        check("expr exits 0", status == 0);
        check("expr result is 42",
              out.find("42") != std::string::npos);
    }

    // 3) String handling: exercises the Utf/StringObj code paths.
    {
        std::string cmd =
            "echo puts [string reverse hello] | " + quote(tclsh);
        int status;
        std::string out = run_capture(cmd, &status);
        std::fprintf(stdout, "\n[string reverse] %s\nexit=%d out=%s",
                     cmd.c_str(), status, out.c_str());
        check("string reverse exits 0", status == 0);
        check("string reverse produced olleh",
              out.find("olleh") != std::string::npos);
    }

    delete r;

    std::fprintf(stdout, "\n%d failure(s)\n", failures);
    return failures ? 1 : 0;
}
