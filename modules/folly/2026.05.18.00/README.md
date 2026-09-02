# Folly 2026.05.18.00 Bazel overlay

The BUILD overlay is adapted from the Bazel Central Registry overlay for
`folly@2025.01.13.00.bcr.6` and reconciled with the public upstream
`v2026.05.18.00` source tree. Targets were updated for sources that were added,
moved, or removed, and obsolete experimental and test-only targets were
pruned.

When updating this module:

1. Reconcile the overlay with the new upstream source layout.
2. Run Buildifier over all Bazel files in the module version directory.
3. Regenerate `source.json` integrity hashes.
4. Build `@folly//folly/...` to validate the complete overlay.
