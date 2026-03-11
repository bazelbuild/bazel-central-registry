# sdl2_mixer

BCR packaging summary for SDL2_mixer.

Public targets:

- `@sdl2_mixer`
- `@sdl2_mixer//:sdl2_mixer_headers`

Packaging notes:

- `@sdl2_mixer//:sdl2_mixer_headers` exports the public SDL2_mixer header only.
- Internal `src/**/*.h` headers and include paths are kept private to the `@sdl2_mixer` implementation.
- The packaged built-in codec sources carry a mix of upstream licenses: SDL_mixer (`LICENSE.txt`), dr_libs (`src/codecs/dr_libs/LICENSE`), minimp3 (`src/codecs/minimp3/LICENSE`), stb_vorbis (`src/codecs/stb_vorbis/stb_vorbis.h`), and TiMidity (`src/codecs/timidity/COPYING`).

Enabled backends:

- Common: WAV, Ogg Vorbis via `stb_vorbis`, FLAC via `dr_flac`, MP3 via `minimp3`, and TiMidity MIDI.
- Linux: external command playback (`MUSIC_CMD`) plus the common built-in codecs.
- macOS: native MIDI plus the common built-in codecs.
- Windows: native MIDI plus the common built-in codecs.

Limitations:

- Optional codec backends requiring extra third-party libraries are currently excluded.
- Linux build does not enable libvorbis/tremor, Opus, WavPack, libxmp, FluidSynth, GME, or other system-library-backed optional decoders.
- macOS and Windows native MIDI paths are build-covered in presubmit, but runtime behavior depends on the host multimedia stack.
- Linux `MUSIC_CMD` support is enabled via explicit Bazel defines rather than a generated config header.

Presubmit:

- Builds and tests both `@sdl2_mixer//:sdl2_mixer_headers_consumer_compile_test` and `@sdl2_mixer//:sdl2_mixer_consumer_link_test`.
