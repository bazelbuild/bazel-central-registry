"""Watchman binary rule with required transitive C++ settings."""

load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@with_cfg.bzl", "with_cfg")

_watchman_builder = with_cfg(cc_binary)
_watchman_builder.extend("copt", ["-O2"])
_watchman_builder.extend("cxxopt", ["-std=gnu++20"])
watchman_binary, _watchman_binary_internal = _watchman_builder.build()
