# libgps

Bazel overlay for [gpsd](https://gpsd.io/) `libgps`.

## Overlay Files

The overlay adds a hand-authored `include/gpsd_config.h` because upstream
generates this header from SCons configuration checks before compiling
`libgps`.

When bumping libgps to a newer gpsd release:

1. Compare upstream `SConstruct` and `SConscript` configuration checks with the
   defines in `overlay/include/gpsd_config.h`.
2. Update `overlay/include/gpsd_config.h` for changed version constants,
   protocol constants, feature checks, and platform-specific defines.
3. Run `bazel run //tools:update_integrity` after modifying overlay files.
4. Verify the targets listed in `modules/libgps/<version>/presubmit.yml`.

The generated `ais_json.i` and `libgps/gps_maskdump.c` files are produced by
Bazel during the build and are not checked into the overlay.
