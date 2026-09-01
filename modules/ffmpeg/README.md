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
| `@ffmpeg//:postproc`   | Video post-processing library (7.1.1 only; not present in 9.0.1) |

#### Bare targets vs `with_defaults/` targets

Every library and binary target has two forms:

- **Bare target** (e.g. `@ffmpeg//:avcodec`) — all component flags default to `False`. No codecs, muxers, demuxers, or filters are compiled in unless you explicitly enable them via `--@ffmpeg//:enable_<component>=True`.
- **`with_defaults/` target** (e.g. `@ffmpeg//:with_defaults/avcodec`) — a Bazel transition enables the precomputed component profile for the target platform (OS + CPU). Additional components can be enabled explicitly with the same component flags as bare targets.

Use `with_defaults/` for most applications. Use bare targets when you need precise control over binary size by enabling only specific components.

### Binaries

| Target              | Description                |
| ------------------- | -------------------------- |
| `@ffmpeg//:ffmpeg`  | Media transcoding tool     |
| `@ffmpeg//:ffprobe` | Media stream analysis tool |

Both also have `with_defaults/` variants (e.g. `@ffmpeg//:with_defaults/ffmpeg`).

Note that there is no `ffplay` binary as it requires SDL2 which is not in the bazel-central-registry. ([bazelbuild/bazel-central-registry#7077](https://github.com/bazelbuild/bazel-central-registry/issues/7077))

### Install tree

For consumers that need FFmpeg as files on disk instead of Bazel `cc_library`
targets, the module exposes install-tree targets:

- `@ffmpeg//:gen_dir` — the bare, fully user-controlled install tree
- `@ffmpeg//:with_defaults/gen_dir` — the platform-default convenience install
  tree

Building either target materializes an install-style directory tree containing:

- `include/` with the headers exported through Bazel's C++ compilation
  context for the FFmpeg libraries
- `lib/` with the built FFmpeg libraries and native library dependencies
- `link-flags.txt` with additional linker flags needed to consume the libraries

This is useful for packaging workflows, generated toolchains, or integrations
that expect an `include/` + `lib/` layout.

`gen_dir` follows the bare target behavior: all component flags default to
`False`, and codecs, muxers, demuxers, filters, and protocols are only compiled
in when explicitly enabled with `--@ffmpeg//:enable_<component>=True`.
Use `with_defaults/gen_dir` when you want FFmpeg's platform-appropriate default
component set. Extra components can still be enabled with the same flags:

```bash
bazel build @ffmpeg//:gen_dir --@ffmpeg//:enable_http_protocol=True
bazel build @ffmpeg//:with_defaults/gen_dir
bazel build @ffmpeg//:with_defaults/gen_dir --@ffmpeg//:enable_http_protocol=True
```

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

### Optional codec libraries in 9.0.1.beta.bcr

The following component flags enable the newly supported BCR libraries. All
flags remain `False` by default, including on `with_defaults/` targets. Enabling
a flag selects the FFmpeg implementation, the required BCR dependency, and the
corresponding `CONFIG_LIB*` definitions. Encoders and decoders can be selected
independently.

| BCR module | Flags (after `--@ffmpeg//:`) |
| ---------- | ------------------------- |
| `codec2@1.2.0` | `enable_libcodec2_decoder`, `enable_libcodec2_encoder` |
| `dav1d@1.5.4` | `enable_libdav1d_decoder` |
| `gsm@1.0.24` | `enable_libgsm_decoder`, `enable_libgsm_encoder`, `enable_libgsm_ms_decoder`, `enable_libgsm_ms_encoder` |
| `lame@4.0` | `enable_libmp3lame_encoder` |
| `libjxl@0.12.0.bcr.1` | `enable_libjxl_decoder`, `enable_libjxl_encoder`, `enable_libjxl_anim_decoder`, `enable_libjxl_anim_encoder` |
| `openjpeg@2.5.4` | `enable_libopenjpeg_encoder` |
| `rav1e@0.8.1` | `enable_librav1e_encoder` |
| `shine@3.1.1` | `enable_libshine_encoder` |
| `speex@1.2.1` | `enable_libspeex_decoder`, `enable_libspeex_encoder` |
| `twolame@0.4.0` | `enable_libtwolame_encoder` |
| `vorbis@1.3.7` | `enable_libvorbis_decoder`, `enable_libvorbis_encoder` |
| `xvidcore@1.3.7` | `enable_libxvid_encoder` |

For example, add LAME encoding and dav1d decoding to the platform defaults:

```bash
bazel build @ffmpeg//:with_defaults/ffmpeg \
    --@ffmpeg//:enable_libmp3lame_encoder=True \
    --@ffmpeg//:enable_libdav1d_decoder=True
```

JPEG XL requires a C++17 toolchain; with older compiler defaults, pass
`--cxxopt=-std=c++17 --host_cxxopt=-std=c++17`.
The animation flags do not require the still-image flags. FFmpeg 9.0.1 no
longer has a `libopenjpeg_decoder`; its native `jpeg2000_decoder` remains
available.

This module version requires Bazel 8.5.0 or later because `rav1e@0.8.1` uses
`rules_rs`. Bazel resolves this requirement even when rav1e encoding is off.
The BCR version is `9.0.1.beta.bcr`; `ffmpeg`, `ffprobe`, and `av_version_info()`
continue to report the upstream release version `9.0.1`.

Selecting Xvid, x264, or x265 makes the generated FFmpeg license report
`GPL version 3 or later`, including for OpenSSL 3 configurations. This is the
overlay's common license choice for these external GPL codecs.
`FFMPEG_LICENSE`, `CONFIG_GPLV3`, and `CONFIG_VERSION3` reflect that choice;
`CONFIG_GPL` remains `0`, so selecting an external codec does not also enable
FFmpeg's internal GPL implementations or change the default component profile.

## Adding new versions

The Bazel overlay relies on several generated `.bzl` files that are produced by Python scripts and checked into the overlay. When adding a new FFmpeg version, these must be regenerated **in order** (later steps depend on earlier ones).

| Step | Script                          | Input                                   | Output                                                               | When to re-run                                                                |
| ---- | ------------------------------- | --------------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| 1    | `generate_config_defs.py`       | FFmpeg `configure` script               | `config.h.in`, `libavutil/avconfig.h.in`, `libavutil/ffversion.h.in` | New FFmpeg version (changed `ARCH_LIST`, `HAVE_LIST`, `CONFIG_LIST`)          |
| 2    | `generate_component_defs.py`    | FFmpeg `configure` and component declarations | `component_defs.bzl`                                            | New FFmpeg version (changed components, deps, CONFIG_EXTRA)                   |
| 3    | `generate_component_srcs.py`    | FFmpeg Makefiles + `component_defs.bzl` + `config.h.in` | `component_srcs.bzl`                                  | New FFmpeg version or changed component/configuration definitions              |
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

All generator scripts accept `--version <VERSION>` to target a specific overlay directory (e.g. `7.1.1.bcr.beta.5`). When omitted, the latest version from `metadata.json` is used automatically.

```bash
# Step 1: regenerate config header templates
python3 generate_config_defs.py /path/to/ffmpeg/source

# Step 2: regenerate component declarations and dependencies
python3 generate_component_defs.py /path/to/ffmpeg/source

# Step 3: regenerate per-component source lists
python3 generate_component_srcs.py /path/to/ffmpeg/source

# Step 4: regenerate resolved profiles
python3 generate_resolved_profiles.py

# Target a specific version:
python3 generate_component_srcs.py --version 7.1.1.bcr.beta.5 /path/to/ffmpeg/source
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

#### Configuration headers

Regenerate `config.h.in` and the `libavutil` header templates with
`generate_config_defs.py`. Preserve the autoconf substitutions in `avconfig.h.in`
and the `PACKAGE_VERSION` substitution in `ffversion.h.in`.

#### `component_defs.bzl`

Run `generate_component_defs.py` against the new FFmpeg source tree to update:

| Variable                | Source in `configure`                                                                                                                 |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `COMPONENT_TYPES`       | `DECODER_LIST`, `ENCODER_LIST`, `MUXER_LIST`, `DEMUXER_LIST`, `FILTER_LIST`, `BSF_LIST`, `PROTOCOL_LIST`, `INDEV_LIST`, `OUTDEV_LIST` |
| `PROFILE_EVERYTHING`    | Flat union of all the above lists                                                                                                     |
| `CONFIG_EXTRA_REGISTRY` | `CONFIG_EXTRA` block in `configure`                                                                                                   |
| `FILTER_SYMBOL_MAP`     | `FILTER_LIST` entries mapped to their C symbol names (see `libavfilter/allfilters.c`)                                                 |

The generator preserves the default component policy from `7.1.1.bcr.beta.7`.
Use `--policy-version` to choose another existing overlay when deliberately
changing that policy. It also marks `threads` available, matching
`ffmpeg_config_checks.bzl`, so the new `tee_muxer` dependency on `fifo_muxer`
does not remove `tee_muxer` from the default profile.
Optional TLS, external-library, and platform components
can require explicit `enable_<component>` flags even when their dependencies
are available.

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
`PROFILE_EVERYTHING` from `component_defs.bzl` in the target overlay directory, parses `OBJS-$(CONFIG_*)` lines from the
FFmpeg Makefiles, and writes `component_srcs.bzl` directly to the overlay.

Steps:

1. Update `component_defs.bzl` in the overlay first (the script depends on it).
2. Run:
   ```bash
   python3 generate_component_srcs.py [--version <VERSION>] /path/to/ffmpeg/source
   ```
3. New components are handled automatically as long as `PROFILE_EVERYTHING` is current.

#### Script tunables

The generator reads subsystem names from `CONFIG_EXTRA_REGISTRY`. If the new
FFmpeg version introduces Makefile changes, these settings inside
`generate_component_srcs.py` may need updating:

| Variable                 | When to update                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------ |
| `OBJECT_PREFIXES`        | A supported architecture adds another object-file group                             |
| `MAKEFILE_FEATURES`      | Static Makefile conditions change; keep these consistent with `config.h.in`           |
| `EXTERNAL_FILES_TO_SKIP` | New source files require external/platform headers unavailable in the Bazel build    |
| `LIBS[].sub_makefiles`   | A library gains a new sub-directory with its own `Makefile` (e.g. `libavcodec/vvc/`) |

Architecture Makefiles are discovered recursively, including nested HEVC and
VVC directories. AArch64 source selections also include `neon/Makefile`.
Sources selected by fixed `CONFIG_*` settings in `config.h.in` are emitted
unconditionally and excluded from the conditional source groups.
The generator includes both `STLIBOBJS` and `SHLIBOBJS`: Bazel produces static
and shared libraries, and shared libraries need their own copies of FFmpeg's
hidden helper definitions, as described in `ffbuild/library.mak`.
Shared-group IDs and definition sections are preserved from the immutable
`7.1.1.bcr.beta.7` overlay. Use `--reference-version` to choose another existing
version as the reference; regeneration does not use the output file as input.
FFmpeg 9.0.1 omits Makefile entries for its declared JPEG XL animation codecs.
The generator supplies missing animation entries from the corresponding
still-image entries, while preserving any explicit upstream animation entries.

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
python3 generate_resolved_profiles.py [--version <VERSION>]
```

The script prints a summary of pruned components (with reasons) to stderr, which is useful for verifying that the
right components are being disabled.

### 5. x86 NASM Assembly

FFmpeg uses NASM-syntax `.asm` files for x86 SIMD optimizations (161 files in 7.1.1). These are compiled via
`rules_nasm` and linked into each library through `select()` on `@platforms//cpu:x86_64`.

Key points for new versions:

- Component `.asm` files follow the same component flags as their C initialization files.
- `config.asm` is auto-generated from `config.h` by a `genrule` (converts `#define` to `%define`).
- Template `.asm` files (e.g. `*_template.asm`) must be excluded from `srcs` and listed in `hdrs`.
- Include-only files (`x86inc.asm`, `x86util.asm`) go in `hdrs`, not `srcs`.
- All `nasm_library` targets are tagged `manual` to avoid building on non-x86 platforms.

When updating, check each library's `x86/Makefile` for new `.asm` files. The glob patterns in `BUILD.bazel` pick up
additions automatically. If a new library gains x86 assembly, add a corresponding `nasm_library` target and wire it
into the `cc_variant_library` `srcs`.

For FFmpeg 9.0.1, `libavcodec` uses separate NASM targets for `x86`, `x86/hevc`,
`x86/vvc`, and `x86/h26x`: `rules_nasm` names object files by basename, and those
directories contain different sources with the same basename. The experimental
`libswscale` implementation (`CONFIG_UNSTABLE`) and SVE/SME assembly remain
disabled. The `ffmpeg` graph HTML and CSS are embedded without compression using
FFmpeg's `ffbuild/bin2c.c`.

The 9.0.1 swscale patch keeps `ff_sws_chroma_pos` available with
`CONFIG_UNSTABLE=0`, because `graph.c` also calls it from the legacy scaler.

The 9.0.1 BoringSSL patch uses `BIO_read` for PEM serialization and BoringSSL's
`SSL_set_mtu` and `SSL_max_seal_overhead` for DTLS, because the pinned BoringSSL
does not provide `BIO_read_ex`, `DTLS_set_link_mtu`, or `DTLS_get_data_mtu`.

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
