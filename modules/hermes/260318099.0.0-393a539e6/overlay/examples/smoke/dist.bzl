"""Consumer-root macOS distribution transition."""

load("@with_cfg.bzl", "with_cfg")

_macos_arm64 = with_cfg(native.filegroup)
_macos_arm64.set("platforms", [Label("@llvm//platforms:macos_aarch64")])
_macos_arm64.set("compilation_mode", "opt")
macos_arm64_dist, _macos_arm64_dist_internal = _macos_arm64.build()
