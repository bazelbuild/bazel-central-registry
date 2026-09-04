# Local validation

Retested on 2026-09-04 against the reviewed Cairo, FreeType, libdatrie, and
libthai builds. Pango remains upstream **1.52.1**, with no source patches.

## Build and runtime matrix

| Environment | Bazel versions | Result per version |
| --- | --- | --- |
| Ubuntu 24.04.4 x86_64, GCC 13.3.0 | 7.7.1, 8.4.2, 9.2.0 | 22/22 tests pass |
| Ubuntu 24.04.4 x86_64, Clang 18.1.3, optimized | 9.2.0 | 22/22 tests pass |
| Debian 13.6 x86_64, GCC 14.2.0 | 7.7.1, 8.4.2, 9.2.0 | 22/22 tests pass |

Test result caching was disabled for these runs. The Debian registry mount was
read-only; the image digest was
`sha256:f324c7ff54321e8d9c588493a20244965938ce0aa50bbd1022d38010e9ffc4b1`.

The 22 tests comprise:

- Six Pango tests: a static C++ consumer; independent initial loading of each
  shared library; relocation of the three libraries alone; and explicit
  dictionary loading through runfiles.
- Four Cairo tests, including PNG color glyph rendering and fractional glyph
  positioning.
- One FreeType test checking public PNG configuration and color glyph decoding.
- Two libdatrie trie serialization tests, with static and dynamic linking.
- Nine libthai tests: six upstream tests, explicit dictionary/runfiles
  overrides, and embedded default dictionaries with static/dynamic linking.

All six public Pango library targets build. The standalone Ubuntu consumers
resolve through a local registry containing only these five candidate modules,
with public BCR supplying every other dependency. They use no source overrides.
Bzlmod graph resolution passes on Bazel 7.7.1, 8.4.2, and 9.2.0.

The Pango loading tests use `RTLD_NOW | RTLD_LOCAL`, explicit runfiles paths,
an empty `LD_LIBRARY_PATH`, and an isolated fontconfig with two upstream font
fixtures. They check shared GObject identity, Latin/Arabic layout, known Thai
word boundaries, and colored emoji pixels. `/proc/self/maps` rejects host
copies of the text/graphics stack.

The default loading and relocation tests have no dictionary in their data.
They clear `LIBTHAI_DICTDIR` and exercise libthai's embedded dictionary through
Pango. A separate test retains explicit dictionary loading. A complete Python
launcher/runfiles tree copied with `cp -aL` also passes after relocation, with
no `thbrk.tri` anywhere in that copied tree.

ELF inspection confirms the three expected SONAMEs and `$ORIGIN` search paths.
The core library owns shared dependency implementations; FT2 depends on core
Pango, and PangoCairo depends on FT2/core. Remaining dynamic dependencies are
standard C/C++ runtime libraries from the toolchain/execution platform.

## BCR validation

Official `setup_presubmit_repos` generation, anonymous consumer builds, and
consumer tests pass on Bazel 9.2.0 for FreeType, libdatrie, libthai, and Pango.
The Pango generated consumer builds all six public libraries and passes all
six tests. Generated Pango/libdatrie/libthai MODULE files match their registry
MODULE files without requiring duplicate MODULE overlays.

The official integrity updater, all overlay/patch hashes, Buildifier, Ruff,
and whitespace checks pass. Live BCR validation passes for Pango, libdatrie,
and libthai, with the expected new-module maintainer-review status (exit 42).
Cairo/FreeType source-content validation uses checksum-verified release
archives for hosts previously unreachable from this environment; it passes
with the expected FreeType presubmit-review status. This cached check does
not establish current reachability of those upstream URLs.

Reproduction from a registry containing the candidate modules:

```sh
bazel run //tools:update_integrity -- pango --version=1.52.1
bazel run //tools:bcr_validation -- --check=pango@1.52.1
bazel run //tools:setup_presubmit_repos -- --module=pango@1.52.1
```

Follow the helper's build/test commands. Add `--nocache_test_results` to force
runtime tests to execute again. The same helpers apply to the prerequisite
module versions.

## Publication and platform limits

The tested dependency builds are Cairo's local reviewed follow-up `f50ea8e6`,
FreeType `7cd41b8b`, and libdatrie/libthai `89174a1b`. Cairo's follow-up is staged
until FreeType is published. All prerequisite PRs remain open at this retest;
resolution using only public BCR must be rerun after they merge and their
versions become available. The Pango-only PR remains unpublished.

Only Linux x86_64 was executed here. Other architectures and the prerequisite
modules' macOS/Windows jobs require their declared CI coverage. Pango itself
supports Linux only; libdatrie also declares macOS support.

Distribution-specific rendering comparisons and their artifacts remain outside
`modules/` as local migration evidence. These portable BCR tests do not promise
identical rendering for arbitrary documents or Linux distributions.
