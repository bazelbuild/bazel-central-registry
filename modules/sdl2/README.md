# sdl2

BCR packaging summary for SDL2.

Public targets:

- `@sdl2`
- `@sdl2//:sdl2_headers`

Packaging notes:

- `@sdl2` exports the SDL library and re-exports public headers in both `SDL2/...` and flat `SDL.h` include layouts for consumer compatibility.
- `@sdl2//:sdl2_headers` exports the public SDL headers plus the Bazel-generated `SDL_config.h` in the canonical `SDL2/...` layout.
- Internal `src/**/*.h` headers are kept private to the `@sdl2` implementation.
- The Bazel-managed SDL config header is generated from the upstream template with `rules_cc_autoconf`.

Enabled backends:

- Linux: ALSA audio, X11 and Wayland video, OpenGL ES 2 rendering via EGL, Linux joystick/haptics, pthread timer/loadso/filesystem/power.
- macOS: Cocoa video, CoreAudio audio, Metal/OpenGL rendering, IOKit joystick/haptics, pthread timer/loadso/filesystem/power.
- Windows: WinMM audio, Windows video, Windows joystick/sensor, Windows timer/loadso/filesystem/power.

Build settings (Linux only, all default to `True`):

- `@sdl2//:with_alsa`: ALSA audio.
- `@sdl2//:with_wayland`: Wayland video.
- `@sdl2//:with_x11`: X11 video.

EGL / OpenGL ES 2 are enabled when Wayland or X11 is. With all three off, for example
`--@sdl2//:with_alsa=False --@sdl2//:with_wayland=False --@sdl2//:with_x11=False`, SDL builds
headless (joystick, game controller, haptics, dummy video/audio) without the X11, Wayland or ALSA
dependencies.

Limitations:

- Linux build does not currently enable Wayland `libdecor`, PulseAudio, or PipeWire.
- Linux desktop OpenGL/GLX and Vulkan are not currently enabled in-package.
- macOS currently disables HIDAPI in-package.
- Windows HIDAPI is wired through Bazel `textual_hdrs` because SDL textually includes `src/hidapi/windows/hid.c`.

Presubmit:

- Builds and tests `@sdl2//:sdl2_headers_consumer_compile_test` for `SDL2/...` includes and `@sdl2//:sdl2_consumer_link_test` for flat `SDL.h` includes.
- Builds and tests `@sdl2//:sdl2_consumer_link_test` on Linux with all backend settings off.
- Uses the standard module presubmit path across all supported platforms on Bazel 8, Bazel 9, and rolling.
