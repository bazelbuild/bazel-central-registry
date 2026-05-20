/**
 * @file iverilog_smoke_test.cc
 * @brief Smoke test for iverilog binaries using Bazel runfiles.
 *
 * Locates iverilog binaries via the Bazel runfiles library and exercises
 * them to verify they are functional.
 *
 * Usage: iverilog_smoke_test <ivlpp_rloc>
 */

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

static std::string run_capture(const std::string &cmd, int *exit_status) {
  FILE *pipe = popen(cmd.c_str(), "r");
  if (!pipe) {
    *exit_status = -1;
    return "";
  }
  std::string output;
  char buf[512];
  while (fgets(buf, sizeof(buf), pipe)) {
    output += buf;
  }
  *exit_status = pclose(pipe);
  return output;
}

static void check(const char *label, bool condition) {
  if (condition) {
    fprintf(stdout, "  PASS: %s\n", label);
  } else {
    fprintf(stderr, "  FAIL: %s\n", label);
    ++failures;
  }
}

static std::string resolve(Runfiles *r, const char *rlocation) {
  std::string path = r->Rlocation(rlocation);
  if (path.empty()) {
    fprintf(stderr, "Cannot resolve runfiles path: %s\n", rlocation);
  }
  return path;
}

static std::string quote(const std::string &s) {
#ifdef _WIN32
  // On Windows, _popen passes the command through cmd.exe /c which has
  // complex double-quote parsing rules.  Paths from Bazel runfiles
  // never contain spaces, so skip quoting to avoid cmd.exe issues.
  return s;
#else
  return "\"" + s + "\"";
#endif
}

// Test the iverilog driver by running "iverilog -V" and verifying
// that it prints its version string and exits cleanly.
// The IVL_BASE environment variable must point to the assembled
// base directory so the driver can locate its components.
static void test_iverilog(Runfiles *r, const char *rlocation) {
  fprintf(stdout, "--- iverilog version test ---\n");
  std::string bin = resolve(r, rlocation);
  if (bin.empty()) {
    ++failures;
    return;
  }

  // Resolve IVL_BASE from the environment.  The Bazel test rule sets
  // IVL_BASE_RLOCATIONPATH to an rlocationpath; resolve it through runfiles.
  const char *ivl_base_rloc = getenv("IVL_BASE_RLOCATIONPATH");
  if (!ivl_base_rloc) {
    fprintf(stderr, "  FAIL: IVL_BASE_RLOCATIONPATH not set\n");
    ++failures;
    return;
  }
  std::string ivl_base = r->Rlocation(ivl_base_rloc);
  if (ivl_base.empty()) {
    fprintf(stderr, "  FAIL: cannot resolve IVL_BASE rlocation: %s\n",
            ivl_base_rloc);
    ++failures;
    return;
  }

  // Set IVL_BASE in the process environment so the driver subprocess
  // inherits it via popen().  This is cross-platform (no shell tricks).
#ifdef _WIN32
  _putenv_s("IVL_BASE", ivl_base.c_str());
#else
  setenv("IVL_BASE", ivl_base.c_str(), 1);
#endif

  std::string cmd = quote(bin) + " -V 2>&1";
  fprintf(stdout, "  CMD: %s\n", cmd.c_str());
  fprintf(stdout, "  IVL_BASE: %s\n", ivl_base.c_str());

  int status;
  std::string out = run_capture(cmd, &status);

  fprintf(stdout, "  EXIT: %d (0x%x)\n", status, status);
  if (!out.empty()) {
    fprintf(stdout, "  OUTPUT (%d bytes):\n%s\n", (int)out.size(),
            out.substr(0, 2048).c_str());
  } else {
    fprintf(stdout, "  OUTPUT: (empty)\n");
  }

  check("iverilog exits 0", status == 0);
  check("output contains version",
        out.find("Icarus Verilog version") != std::string::npos);
}

// Test the Verilog preprocessor (ivlpp) by feeding it a file with a
// `define directive and verifying that macro expansion occurs.
static void test_ivlpp(Runfiles *r, const char *rlocation) {
  fprintf(stdout, "--- ivlpp preprocess test ---\n");
  std::string bin = resolve(r, rlocation);
  if (bin.empty()) {
    ++failures;
    return;
  }

  // Write a minimal Verilog file with a preprocessor macro.
  const char *tmpdir = getenv("TEST_TMPDIR");
  if (!tmpdir) tmpdir = "/tmp";
  std::string vfile = std::string(tmpdir) + "/smoke_test.v";
  FILE *f = fopen(vfile.c_str(), "w");
  if (!f) {
    fprintf(stderr, "  FAIL: cannot create %s\n", vfile.c_str());
    ++failures;
    return;
  }
  fprintf(f,
          "`define GREETING \"Hello\"\n"
          "module hello;\n"
          "  initial $display(`GREETING);\n"
          "endmodule\n");
  fclose(f);

  std::string cmd = quote(bin) + " " + quote(vfile) + " 2>&1";
  fprintf(stdout, "  CMD: %s\n", cmd.c_str());

  int status;
  std::string out = run_capture(cmd, &status);

  fprintf(stdout, "  EXIT: %d (0x%x)\n", status, status);
  if (!out.empty()) {
    fprintf(stdout, "  OUTPUT (%d bytes):\n%s\n", (int)out.size(),
            out.substr(0, 2048).c_str());
  } else {
    fprintf(stdout, "  OUTPUT: (empty)\n");
  }

  check("ivlpp exits 0", status == 0);
  check("macro expanded", out.find("\"Hello\"") != std::string::npos);
  check("output contains module", out.find("module hello") != std::string::npos);
}

int main(int argc, char *argv[]) {
  if (argc < 3) {
    fprintf(stderr, "usage: %s <ivlpp_rloc> <iverilog_rloc>\n", argv[0]);
    return 1;
  }

  std::string error;
  Runfiles *r = Runfiles::Create(argv[0], &error);
  if (!r) {
    fprintf(stderr, "Runfiles error: %s\n", error.c_str());
    return 1;
  }

  test_ivlpp(r, argv[1]);
  test_iverilog(r, argv[2]);

  delete r;

  fprintf(stdout, "\n%d failure(s)\n", failures);
  return failures ? 1 : 0;
}
