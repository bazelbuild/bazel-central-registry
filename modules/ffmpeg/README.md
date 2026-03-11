# ffmpeg

The `ffmpeg` module is a hand crafted port from the original `configure` build scripts.

## Structure

### Libraries

Each FFmpeg library is available as a `cc_library` target with two variants:

| Target                 | Description                                                       |
| ---------------------- | ----------------------------------------------------------------- |
| `@ffmpeg//:avutil`     | Core utility library (pixel formats, math, logging, memory, etc.) |
| `@ffmpeg//:avcodec`    | Codec encoding/decoding library                                   |
| `@ffmpeg//:avformat`   | Container muxing/demuxing and I/O library                         |
| `@ffmpeg//:avfilter`   | Audio/video filter graph library                                  |
| `@ffmpeg//:avdevice`   | Device capture/playback library                                   |
| `@ffmpeg//:swresample` | Audio resampling and format conversion library                    |
| `@ffmpeg//:swscale`    | Video scaling and pixel format conversion library                 |
| `@ffmpeg//:postproc`   | Video post-processing library                                     |

#### Bare targets vs `with_defaults/` targets

Every library and binary target has two forms:

- **Bare target** (e.g. `@ffmpeg//:avcodec`) — all component flags default to `False`. No codecs, muxers, demuxers, or filters are compiled in unless you explicitly enable them via `--@ffmpeg//:enable_<component>=True`.
- **`with_defaults/` target** (e.g. `@ffmpeg//:with_defaults/avcodec`) — a Bazel transition automatically enables all components appropriate for the target platform (OS + CPU). This matches a typical `./configure && make` build.

Use `with_defaults/` for most applications. Use bare targets when you need precise control over binary size by enabling only specific components.

### Binaries

| Target              | Description                |
| ------------------- | -------------------------- |
| `@ffmpeg//:ffmpeg`  | Media transcoding tool     |
| `@ffmpeg//:ffprobe` | Media stream analysis tool |

Both also have `with_defaults/` variants (e.g. `@ffmpeg//:with_defaults/ffmpeg`).

Note that there is no `ffplay` binary as it requires SDL2 which is not in the bazel-central-registry. ([bazelbuild/bazel-central-registry#7077](https://github.com/bazelbuild/bazel-central-registry/issues/7077))

### Component flags

FFmpeg codecs, muxers, demuxers, parsers, bitstream filters, filters, and device I/O modules are individually gated by `bool_flag` settings. Each flag defaults to `False` and can be enabled on the command line or via `.bazelrc`:

```bash
bazel build @ffmpeg//:avcodec --@ffmpeg//:enable_h264_decoder=True --@ffmpeg//:enable_aac_decoder=True
```

The flag naming convention follows FFmpeg's configure script: `enable_<component>` where `<component>` is the lowercase name with type suffix. Examples:

| Flag                          | Component type   |
| ----------------------------- | ---------------- |
| `enable_h264_decoder`         | Decoder          |
| `enable_aac_encoder`          | Encoder          |
| `enable_mp4_muxer`            | Muxer            |
| `enable_mov_demuxer`          | Demuxer          |
| `enable_h264_parser`          | Parser           |
| `enable_h264_mp4toannexb_bsf` | Bitstream filter |
| `enable_scale_filter`         | Filter           |
| `enable_alsa_indev`           | Input device     |
| `enable_alsa_outdev`          | Output device    |

## Adding new versions

The Bazel overlay relies on several generated `.bzl` files that are produced by Python scripts and checked into the overlay. When adding a new FFmpeg version, these must be regenerated **in order** (later steps depend on earlier ones).

| Step | Script                          | Input                                   | Output                                                               | When to re-run                                                                |
| ---- | ------------------------------- | --------------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| 1    | `generate_config_defs.py`       | FFmpeg `configure` script               | `config.h.in`, `libavutil/avconfig.h.in`, `libavutil/ffversion.h.in` | New FFmpeg version (changed `ARCH_LIST`, `HAVE_LIST`, `CONFIG_LIST`)          |
| 2    | Manual                          | FFmpeg `configure` script               | `component_defs.bzl`                                                 | New FFmpeg version (changed components, deps, CONFIG_EXTRA)                   |
| 3    | `generate_component_srcs.py`    | FFmpeg Makefiles + `component_defs.bzl` | `component_srcs.bzl`                                                 | New FFmpeg version or changed `component_defs.bzl`                            |
| 4    | `generate_resolved_profiles.py` | `component_defs.bzl`                    | `component_resolved.bzl`                                             | Changed `component_defs.bzl` (new components, deps, profiles, available libs) |

### Why resolution is pre-computed

Unlike FFmpeg's `configure` script which probes the build host for available libraries and features, Bazel's environment is fully static: library availability is determined by `MODULE.bazel`, and component selection is a build-time choice via `bool_flag` settings. There is no system to probe at build time for component selection purposes (system capability detection is handled separately by `rules_cc_autoconf`).

Because the dependency graph is static, `generate_resolved_profiles.py` pre-computes the full transitive closure of component dependencies for each (OS, CPU) combination and writes the results as flat dicts in `component_resolved.bzl`. The structure is:

- Private `_RESOLVED_{OS}` dicts with the common resolved state per OS
- Public `RESOLVED_{OS}_{CPU}` names (aliased to the OS base when identical, or full dicts when CPU-specific overrides exist)
- A `RESOLVED_COMPONENTS` map keyed by `"{os}-{cpu}"` (e.g. `"linux-x86_64"`) consumed by the transition
- A `RESOLVED_DEFAULT` fallback for unknown platforms

The Bazel transition constructs the key from `attr.os` and `attr.cpu`, then does a single dict lookup -- no iterative resolution loops at build time.

### Quick reference

```bash
# Step 1: regenerate config header templates
python3 generate_config_defs.py /path/to/ffmpeg/source --output-dir .

# Step 3: regenerate per-component source lists
python3 generate_component_srcs.py /path/to/ffmpeg/source > component_srcs.bzl

# Step 4: regenerate resolved profiles
python3 generate_resolved_profiles.py
```

## Adding a New FFmpeg Version to the BCR

When adding new versions, the following steps may be helpful.

### 1. Directory Setup

```bash
cp -r modules/ffmpeg/7.1.1 modules/ffmpeg/<NEW_VERSION>
```

Add `"<NEW_VERSION>"` to `metadata.json` `"versions"` array.

### 2. Files to Update

All paths below are relative to `modules/ffmpeg/<NEW_VERSION>/`.

#### `config_defs.bzl`

Update the version string in `FFVERSION_H`.

#### `component_defs.bzl`

Re-extract from the new FFmpeg `configure` script:

| Variable                | Source in `configure`                                                                                                                 |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `COMPONENT_TYPES`       | `DECODER_LIST`, `ENCODER_LIST`, `MUXER_LIST`, `DEMUXER_LIST`, `FILTER_LIST`, `BSF_LIST`, `PROTOCOL_LIST`, `INDEV_LIST`, `OUTDEV_LIST` |
| `PROFILE_EVERYTHING`    | Flat union of all the above lists                                                                                                     |
| `CONFIG_EXTRA_REGISTRY` | `CONFIG_EXTRA` block in `configure`                                                                                                   |
| `FILTER_SYMBOL_MAP`     | `FILTER_LIST` entries mapped to their C symbol names (see `libavfilter/allfilters.c`)                                                 |

#### `ffmpeg_config_checks.bzl`

Diff the new `configure` for added/removed/changed feature-detection checks and mirror them as `checks.AC_TRY_COMPILE` entries.

#### `BUILD.bazel`

Update unconditional source lists (`_AVUTIL_SRCS`, `_AVCODEC_BASE_SRCS`, etc.) by diffing the new Makefiles'
unconditional `OBJS =` / `OBJS +=` lines. Check for new/removed headers in glob patterns and any new library dependencies.

#### Test `BUILD.bazel` files

Add or remove test targets in `libavcodec/tests/`, `libavfilter/tests/`, `libavutil/tests/`, `libswscale/tests/`, and
`tests/` if test sources changed.

### 3. Regenerating `component_srcs.bzl`

`generate_component_srcs.py` (at `modules/ffmpeg/generate_component_srcs.py`) is reusable across versions. It reads
`PROFILE_EVERYTHING` from `component_defs.bzl` **in the same directory as the script**, parses `OBJS-$(CONFIG_*)` lines
from the FFmpeg Makefiles, and writes `component_srcs.bzl` to stdout.

Steps:

1. Update `component_defs.bzl` in the overlay first (the script depends on it).
2. Copy or symlink `generate_component_srcs.py` into the overlay directory.
3. Run:
   ```bash
   python3 generate_component_srcs.py /path/to/ffmpeg/source > $VERSION/overlay/component_srcs.bzl
   ```
4. New components are handled automatically as long as `PROFILE_EVERYTHING` is current.

#### Script tunables

If the new FFmpeg version introduces changes, these lists inside `generate_component_srcs.py` may need updating:

| Variable                 | When to update                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------ |
| `CONFIG_EXTRA`           | New internal subsystem flags appear in `configure`'s `CONFIG_EXTRA` block            |
| `EXTERNAL_FILES_TO_SKIP` | New source files require external/platform headers unavailable in the Bazel build    |
| `LIBS[].sub_makefiles`   | A library gains a new sub-directory with its own `Makefile` (e.g. `libavcodec/vvc/`) |

### 4. Regenerating `component_resolved.bzl`

`generate_resolved_profiles.py` reads `component_defs.bzl` and pre-computes the resolved component state for each (OS,
CPU) combination:

- **linux** (aarch64, x86_64): `CONFIGURE_DEFAULT_COMPONENTS + LINUX_COMPONENTS`
- **macos** (aarch64, x86_64): `CONFIGURE_DEFAULT_COMPONENTS + MACOS_COMPONENTS`
- **windows** (aarch64, x86_64): `CONFIGURE_DEFAULT_COMPONENTS + WINDOWS_COMPONENTS`
- **default**: `CONFIGURE_DEFAULT_COMPONENTS`

Currently the aarch64 and x86_64 profiles for each OS are identical (architecture-specific behavior is handled by
`select()` on source files, not component flags). When CPU-specific component lists are added to `component_defs.bzl`,
the generator will produce distinct dicts per (OS, CPU) pair automatically.

For each profile, the script:

1. Enables all components in the profile
2. Propagates `select` and `suggest` edges to a fixpoint
3. Prunes components whose `deps`, `deps_any`, `conflict`, or `select` constraints are not satisfiable

Run after any change to `component_defs.bzl`:

```bash
python3 generate_resolved_profiles.py
```

The script prints a summary of pruned components (with reasons) to stderr, which is useful for verifying that the
right components are being disabled.

### 5. x86 NASM Assembly

FFmpeg uses NASM-syntax `.asm` files for x86 SIMD optimizations (161 files in 7.1.1). These are compiled via
`rules_nasm` and linked into each library through `select()` on `@platforms//cpu:x86_64`.

Key points for new versions:

- All `.asm` files are compiled unconditionally; the C init files gate registration via `HAVE_X86ASM` and component flags.
- `config.asm` is auto-generated from `config.h` by a `genrule` (converts `#define` to `%define`).
- Template `.asm` files (e.g. `*_template.asm`) must be excluded from `srcs` and listed in `hdrs`.
- Include-only files (`x86inc.asm`, `x86util.asm`) go in `hdrs`, not `srcs`.
- All `nasm_library` targets are tagged `manual` to avoid building on non-x86 platforms.

When updating, check each library's `x86/Makefile` for new `.asm` files. The glob patterns in `BUILD.bazel` pick up
additions automatically. If a new library gains x86 assembly, add a corresponding `nasm_library` target and wire it
into the `cc_variant_library` `srcs`.

### 6. External Library Dependencies

Components that wrap external libraries (e.g. `libx264_encoder`, `alsa_indev`) need conditional `select()` entries in
the library target's `deps` so the external library is linked only when the component is enabled. The pattern is:

```starlark
deps = [...] + select({
    "//:enable_libx264_encoder_is_true": ["@x264"],
    "//conditions:default": [],
}),
```

When adding a new version, check `COMPONENT_REGISTRY` in `component_defs.bzl` for entries with `"deps"` fields. If the
dep maps to a `bazel_dep` in `MODULE.bazel`, ensure a matching `select()` exists on the appropriate library target
(`avcodec`, `avformat`, `avfilter`, or `avdevice`).

Dependencies listed as `"suggest"` (e.g. `bzlib`, `lzma`) are optional -- the source code guards their usage behind
autoconf `CONFIG_*` flags and compiles without them.

## Bug Report Guidance

FFmpeg is a colossal project with enormous configurability. The Bazel Central Registry CI
does not have sufficient infrastructure to test all supported FFmpeg components and features.

**Consumers are asked to open a pull-request, not just file an issue.** The maintainers
of this FFmpeg Bazel integration are not users of every component or feature, and cannot be
expected to diagnose and fix bugs they cannot reproduce. Fixes depend on contributions from
the consumers who encounter them.

When identifying and reporting issues, please take the following steps:

1. Follow Bazel Central Registry guidance to create the issue.
2. Open a pull-request with the fix by introducing a new `.bcr.*` variant for the affected version.
3. Expand the presubmit pipelines where possible to add regression testing for the affected feature.
