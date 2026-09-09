// Integration check: run `openFPGALoader --scan-usb` end-to-end.
//
// libusb_init() opens /dev/bus/usb and a NETLINK_KOBJECT_UEVENT socket on
// Linux, IOKit on macOS, WinUSB on Windows — none of which are reachable from
// Bazel's default sandbox. This target is tagged `no-sandbox` in BUILD.bazel
// so the test process gets host access and libusb has a chance of succeeding.
//
// Even so, we assert only that the libusb code path was actually reached:
// success prints a "Bus device" header, and a controlled failure (e.g.
// libusb_init returning an error) still surfaces libusb by name. A real
// segfault or a build that dropped the libusb path would produce output with
// no libusb marker at all, which is the regression this test catches.

#include <string>

#include "gtest/gtest.h"
#include "openfpga_test_util.hpp"

namespace {

using openfpga_test::OpenFpgaLoaderBinary;
using openfpga_test::Result;
using openfpga_test::RunWithArg;

TEST(OpenFpgaLoaderUsbScanTest, LibusbCodePathReached) {
    const std::string& bin = OpenFpgaLoaderBinary();
    ASSERT_FALSE(bin.empty());

    Result r = RunWithArg(bin, "--scan-usb");
    const bool scanned =
        r.exit_code == 0 &&
        r.output.find("Bus device") != std::string::npos;
    const bool controlled_libusb_failure =
        r.output.find("libusb") != std::string::npos;
    EXPECT_TRUE(scanned || controlled_libusb_failure)
        << "--scan-usb neither scanned successfully nor produced any libusb "
           "output (exit " << r.exit_code << "); got:\n" << r.output;
}

}  // namespace
