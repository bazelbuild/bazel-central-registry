# sdl3

This module builds SDL 3 from source with rules_cc, as a static library. It has
no shared library target. `overlay/BUILD.bazel` documents the build.

## Targets

The module supplies these targets. The CMake name of each target is in
parentheses:

- `@sdl3` (`SDL3::SDL3-static`)
- `@sdl3//:sdl3_headers` (`SDL3::Headers`)
- `@sdl3//:sdl3_test` (`SDL3::SDL3_test`)

A consumer depends on `@sdl3` alone and includes `<SDL3/SDL.h>`. That target
carries the public headers, so the build satisfies `layering_check`.

The module supports Linux, macOS and Windows. On other platforms `@sdl3` is
incompatible, and a wildcard build therefore skips it. The module needs Bazel
7.4.0 or newer, because rules_cc_autoconf uses `attr.string_keyed_label_dict`.

On macOS, `cc_library` compiles SDL's Objective-C sources. A consumer needs no
`apple_support` dependency and no special `bazel_dep` order.

## What the module builds

On Windows and macOS, the module uses the build configuration headers that
SDL supplies in `include/build_config/`. On Linux, the module generates that
header with rules_cc_autoconf, from the checks in `sdl3_config_checks.bzl`,
which copy SDL's own CMake checks.

On Linux the module enables the ALSA audio driver and the X11 and Wayland
video drivers. It also enables OpenGL through EGL, OpenGL ES 2, Vulkan, the
V4L2 camera driver, and the evdev joystick and haptic drivers.

The module disables each backend that has no Bazel module: PulseAudio,
PipeWire, JACK, sndio, OSS, KMSDRM, libdecor, D-Bus, libudev, libusb,
liburing, GLX, XScrnSaver, XTest, fribidi and libthai.

## Runtime requirements

SDL loads X11, Wayland, ALSA and xkbcommon at runtime by soname, and Bazel
links none of them into a consumer. Two of them have a minimum version on the
machine that runs the program:

- libwayland-client 1.20 or newer. The generated protocol code calls
  `wl_proxy_marshal_flags`. If that symbol is absent, SDL does not use the
  Wayland driver.
- libxkbcommon 0.5.0 or newer, which is the minimum version in SDL's
  pkg-config specification.

## Patches

The module applies one patch, upstream commit
[32c19b9dc](https://github.com/libsdl-org/SDL/commit/32c19b9dc8c229e239434fedc94541c6abb3f84a).
That commit stops a read past the end of a buffer in `test/testprocess.c`.
No 3.4.x release contains it. Delete `patches/` and the `patches` entry in
`source.json` when a release contains it.

## Tests

The `@sdl3//test` package runs the non-interactive programs of
`test/CMakeLists.txt` headless, on the dummy video driver and the dummy audio
driver. The one program left out is pretest, which upstream builds for 32-bit
Windows only. The presubmit matrix also builds `overlay/test_module`, which
links `@sdl3` as a consumer links it.

## Upgrading

1. Compare `include/build_config/SDL_build_config.h.cmake` between the two
   releases. Write a check in `sdl3_config_checks.bzl` for each new
   `#cmakedefine`. Delete the check for each entry that upstream removed.
2. Compare the `sdl_glob_sources` and `sdl_sources` calls in `CMakeLists.txt`
   with the source lists in `overlay/BUILD.bazel`. Add a glob for each new
   backend directory. testsymbols fails to link if a source file is absent.
3. Examine `test/testprocess.c` in the new release. If that file limits the
   EOF search with `SDL_strnstr`, delete the patch as above.
4. Set the new version in `MODULE.bazel` and in `overlay/MODULE.bazel`. Keep
   the two files identical, because `bcr_validation` compares them.
5. Change the `release-3.4.16` links in `overlay/` to the new release tag.
   Correct each line anchor that moved.
6. Update the hashes with `bazel run //tools:update_integrity -- sdl3
   --version=<new>`. Then start the presubmit matrix.

`sdl3_config_checks.bzl` gives the procedure to compare the generated Linux
header with the output of SDL's own configure step.

## License

SDL 3 is under the zlib license. `@sdl3//:LICENSE.txt` has the text.
