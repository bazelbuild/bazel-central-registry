// Cross-platform smoke tests for the built openFPGALoader binary. Upstream
// ships no unit tests, so these cover "compiles into something that remotely
// works": exercise --Version and --help through popen and assert on exit
// status + expected substrings.
//
// The libusb-exercising `--scan-usb` check lives in usb_scan_test.cc (tagged
// `no-sandbox` because libusb_init() fails in Bazel's default sandbox).

#include <string>

#include "gtest/gtest.h"
#include "openfpga_test_util.hpp"

namespace {

using openfpga_test::OpenFpgaLoaderBinary;
using openfpga_test::Result;
using openfpga_test::RunWithArg;

TEST(OpenFpgaLoaderSmokeTest, Version) {
    const std::string& bin = OpenFpgaLoaderBinary();
    ASSERT_FALSE(bin.empty());

    Result r = RunWithArg(bin, "--Version");
    EXPECT_EQ(r.exit_code, 0) << "output:\n" << r.output;
    EXPECT_NE(r.output.find("v1.1.1"), std::string::npos)
        << "expected version output to contain 'v1.1.1', got:\n" << r.output;
}

TEST(OpenFpgaLoaderSmokeTest, Help) {
    const std::string& bin = OpenFpgaLoaderBinary();
    ASSERT_FALSE(bin.empty());

    Result r = RunWithArg(bin, "--help");
    EXPECT_EQ(r.exit_code, 0) << "output:\n" << r.output;
    static const char* kExpected[] = {
        "openFPGALoader",
        "--cable",
        "--bitstream",
    };
    for (const char* needle : kExpected) {
        EXPECT_NE(r.output.find(needle), std::string::npos)
            << "--help output missing '" << needle
            << "', got:\n" << r.output;
    }
}

}  // namespace
