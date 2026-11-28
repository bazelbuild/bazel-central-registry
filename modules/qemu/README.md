# QEMU Bazel overlay

This is a downstream Bazel build, not QEMU's upstream build system. The
upstream release archive is unchanged. The overlay is maintained in
[sonix-network/qemu-bazel](https://github.com/sonix-network/qemu-bazel).
The initial scope of the `qemu` module is a static Linux x86-64 system
emulator with KVM and no TCG. It does not replace the `rules_qemu`
toolchain rules, and consumers supply a static-capable C toolchain.

The checked-in BUILD files describe QEMU's source sets. Device selection
runs QEMU's Kconfig generator under rules_python's managed host interpreter;
other generators run in build actions. The emulator, its build information,
release `pc-bios` files, package metadata, and Linux x86-64 `qemu-img` for the
`rules_qemu` adapter are public. Other binaries and build targets are internal.

GLib, PCRE2, and libslirp resolve through Bzlmod. The GLib and PCRE2 registry
revisions support the static musl build without private copies or registry
URLs in the build rules. The Linux presubmit registers Zig/musl and checks
both the q35-only `minimal` and upstream-device `default` profiles without
booting a guest.

The first registry version is `11.1.2`. Later registry-only changes for the
same QEMU release use new versions and directories `11.1.2.bcr.1`,
`11.1.2.bcr.2`, and so on, without editing a published version.
