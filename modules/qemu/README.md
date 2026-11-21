# QEMU Bazel overlay

This is a downstream Bazel build, not QEMU's upstream build system. The
upstream release archive is unchanged. The Bazel overlay is maintained in
[sonix-network/qemu-bazel](https://github.com/sonix-network/qemu-bazel),
separately from QEMU's source and releases.

The checked-in BUILD files describe the source sets needed for Linux x86-64
system emulation with KVM. Build actions generate configuration and device
selection from the upstream Kconfig and `.mak` inputs, and call the upstream
Python generators for trace and QAPI code. The test module registers a pinned
Zig/musl toolchain. With no profile tag the build selects only q35 and its
Kconfig dependencies; `profile = "default"` selects QEMU's default x86-64
devices. The Linux presubmit checks both profiles without booting a guest.

The static build uses the pinned GLib build overlay from BCR with local musl
and package-metadata adjustments, a pinned PCRE2 build, and an optional pinned
libslirp build for the default profile. Their build adaptations are under
`11.1.2/overlay/bazel/deps/` and `11.1.2/overlay/bazel/libslirp.BUILD.bazel`.

The first registry version is `11.1.2`. Later registry-only changes against the
same QEMU release use new versions and directories `11.1.2.bcr.1`,
`11.1.2.bcr.2`, and so on, without editing a published version.
