// SPDX-License-Identifier: Apache-2.0

#include "embree4/rtcore.h"

#include <cstring>
#include <iostream>

static_assert(RTC_VERSION_MAJOR == 4, "Incorrect Embree major version");
static_assert(RTC_VERSION_MINOR == 4, "Incorrect Embree minor version");
static_assert(RTC_VERSION_PATCH == 1, "Incorrect Embree patch version");
static_assert(RTC_VERSION == 40401, "Incorrect Embree version number");

int main() {
    if (std::strcmp(RTC_VERSION_STRING, "4.4.1") != 0) {
        std::cerr << "Incorrect Embree version string: " << RTC_VERSION_STRING << '\n';
        return 1;
    }

    RTCDevice device = rtcNewDevice(nullptr);
    if (!device) {
        std::cerr << "Embree device creation failed: " << rtcGetDeviceError(nullptr) << '\n';
        return 1;
    }

    const auto version = rtcGetDeviceProperty(device, RTC_DEVICE_PROPERTY_VERSION);
    const auto error = rtcGetDeviceError(device);
    rtcReleaseDevice(device);
    if (error != RTC_ERROR_NONE || version != 40401) {
        std::cerr << "Incorrect Embree runtime version: " << version
                  << ", error: " << error << '\n';
        return 1;
    }
    return 0;
}
