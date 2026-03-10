# sdl2

BCR packaging summary for SDL2.

Public targets:

- `@sdl2`
- `@sdl2//:sdl2_headers`

Packaging notes:

- `@sdl2//:sdl2_headers` exports the public SDL headers plus the Bazel-generated `SDL_config.h`.
- Internal `src/**/*.h` headers are kept private to the `@sdl2` implementation.

Enabled backends:

- Linux: ALSA audio, X11 video, Linux joystick/haptics, pthread timer/loadso/filesystem/power.
- macOS: dummy audio/video, pthread timer/loadso/filesystem.
- Windows: WinMM audio, Windows video, Windows joystick/sensor, Windows timer/loadso/filesystem/power.

Limitations:

- Linux build is X11-oriented (Wayland/Pulse/PipeWire are not enabled).
- macOS build does not enable Cocoa/CoreAudio.
- macOS falls back to plain file opens instead of app-bundle resource lookup.
- The Bazel-managed SDL config header is generated from a checked-in template plus probe checks; backend selection remains defined by the BUILD overlay.

Presubmit:

- Builds and tests both `@sdl2//:sdl2_headers_consumer_compile_test` and `@sdl2//:sdl2_consumer_link_test`.
