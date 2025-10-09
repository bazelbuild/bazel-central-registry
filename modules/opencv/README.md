## Notes on bazelifying an opencv release

Opencv has a lot of configs and optimizations to enable. Generating a native bazel build is quite tedious, but here are the steps I've followed.

These are defined mainly in four files: `cv_cpu_config.h`, `custom_hal.hpp`, `opencv2/opencv_modules.hpp`, and `cvconfig.h`.

#### CPU Optimization Flags

CPU optimization flags (e.g., SIMD operations) are toggled on or off in `cv_cpu_config.h`. These flags are configured based on guidance from the [CPU optimizations wiki](https://github.com/opencv/opencv/wiki/CPU-optimizations-build-options). Ensure that the appropriate flags are enabled for your target architecture to maximize performance.

#### Custom Hardware Abstraction Layer (HAL)

The `custom_hal.hpp` file allows you to define custom hardware acceleration layers. This is useful if you are targeting specialized hardware or need to implement custom optimizations. In an attempt to generalize, I've left this blank

#### Module Configuration

The `opencv2/opencv_modules.hpp` file specifies which OpenCV modules are included in the build. You can modify this file to include or exclude specific modules based on your requirements. These are modules you want (i.e core, calib3d, features2d, etc)

#### Build Configuration

The `cvconfig.h` file contains general build configuration options. This includes settings for third-party dependencies, build flags, and other global configurations.

#### Adding New/Maintaining Modules

The `opencv_module` macro creates a `cc_library` for each module in OpenCV. Note that for each new dispatched file in a module, you'll need to define a mapping of the dispatched file to the actual operation. For example:

```python
dispatched_files = {
    "stat": [
        "avx2",
        "sse4_2",
    ]
}
```

These mappings ensure that the correct SIMD or hardware-specific implementation is used during runtime, based on the capabilities of the target architecture. Be sure to review the dispatched files for each module and update the mappings as necessary.

When adding a new module, follow these steps:
1. Add the new module `modules/opencv/4.12.0/overlay/opencv.bzl` to `CONFIG`
2. Use the `opencv_module` macro to define the module's build rules.
3. Update the `dispatched_files` mapping if the module includes hardware-specific optimizations.

If you encounter build issues:
- Verify that all required dependencies are correctly specified in the `BUILD` files.
- Check the `cvconfig.h` file for any missing or misconfigured options.
- Ensure that the `dispatched_files` mappings are accurate and complete.

