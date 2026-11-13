# GRUB

Builds GRUB's host utilities and publishes, as Starlark data, everything a
rule set needs to build the boot-time image for any firmware platform.  The
module itself ships no rules for the image.

## Host utilities

The root package builds what `./configure --with-platform=none && make
install` ships: the programs (`grub-mkimage`, `grub-install`, `grub-probe`,
`grub-editenv`, `grub-file`, `grub-fstest`, ...), the scripts, `etc/grub.d`
and the bash completion, collected in the `:bin` and `:sbin` filegroups.
[`rules_cc_autoconf`](https://registry.bazel.build/modules/rules_cc_autoconf)
runs `configure.ac`'s checks at build time; install directories and optional
dependencies are flags (`--@grub//:libdir`, `enable_liblzma`, ...).
`grub-mount` exists in 2.14 only: 2.06's needs the FUSE 2 API, which the
registry's libfuse (3.x) does not provide.

## The boot image, as data and compile targets

Upstream describes the image outside Bazel: the per-platform source tables in
`grub-core/Makefile.core.def` and `Makefile.gcry.def`, the `TARGET_*` flags
in `configure.ac`, the flag classes and strip lists in `conf/Makefile.common`
and `grub-core/Makefile.am`.  `//platform` carries all of it in Starlark:
`<platform>.bzl` exports one dict per platform (`I386_PC`, `ARM64_EFI`, ...,
plus `mipsel_arc` and `mipsel_qemu_mips`) with the kernel, module and image
tables, sources as `Label()`s, the flags and the `config.h` values;
`modules.bzl` holds the module entries that are the same on every platform,
which the platform tables refer to by name; `platforms.bzl` indexes the
platforms in `PLATFORM_DATA`; `common.bzl` holds the shared data and
documents the fields.

For each platform the package also declares, from that data:

- `<platform>_flags`, configure's compiler probes as rules_cc_autoconf checks
  run against the configured toolchain, and the resulting `TARGET_*` lists as
  response files (`<platform>/cflags.rsp` and friends);
- `<platform>_config_h`, the kernel arm of `config.h`, with the probed
  `HAVE_ASM_USCORE`;
- a `cc_library` per kernel, module and boot image (`<platform>/kernel`,
  `<platform>/mod/<module>`, `<platform>/image/<image>`, with an `_asm`
  library beside for `.S` sources), compiled with those flags, and
  `<platform>_objects` naming them all.  These are the shared compile step;
  linking, stripping, the `*.lst` files and genmod belong to the rule set
  that takes the objects.

The root package makes public the sources, the configured headers, the
generated parser and trig tables, the `build-grub-module-verifier` tool and
upstream's helper scripts.  Choosing the platform is the consumer's job: the
firmware is not a `@platforms` constraint and the CPU does not tell i386's
seven ports apart.  So is the `-isystem $(cc -print-file-name=include)` that
goes with the `nostdinc` field.

## New releases

Updating the module is two steps.  The first runs from this repository
against the extracted release; the second from a clone of rules_cc_autoconf
beside it:

1. Regenerate the platform data:

   ```
   python3 modules/grub/generate_platform_data.py /path/to/grub-2.14
   ```

   The tables come from gentpl.py's own parser and follow a release
   automatically.  The flag steps are a transcription of `configure.ac`,
   verified for 2.06 and 2.14 against `./configure` on every x86 platform and
   arm64-efi, and the probed response files against the same: diff
   `configure.ac` against `flag_steps` in the script first.

2. Regenerate the root package with rules_cc_autoconf's converter, following
   its [documentation](https://periareon.github.io/rules_cc_autoconf/convert.html):

   ```
   bazel run //tools/convert -- convert --bcr-entry ../bazel-central-registry/modules/grub/2.14
   ```

   It reads `decisions.bzl` and the hand-written `overlay/BUILD.bazel`,
   rewrites `overlay/autoconf.bzl`, the two `MODULE.bazel` files and
   `source.json`, and reports any construct of the new release that needs a
   decision.

Everything else under `overlay/` is maintained by hand: `BUILD.bazel`
(the generated parser and trig tables, the init sources, install-directory
flags, scripts and the `:bin`/`:sbin` filegroups), `geninit.bzl`,
`install_dirs.bzl`, `tests/`, and under `platform/` its `BUILD.bazel`,
`platform.bzl` and `common.bzl`.
