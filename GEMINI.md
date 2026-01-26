# Gemini's Guide to the Bazel Central Registry (BCR)

This guide summarizes the essential workflows and policies for contributing to and maintaining the BCR.

## 📁 Repository Structure
Each module is organized under the `modules/` directory:
- `modules/<name>/metadata.json`: Module-level info (maintainers, versions, homepage).
- `modules/<name>/<version>/`:
    - `MODULE.bazel`: The module's dependency definition.
    - `source.json`: Source archive URL, integrity (SHA-256), and optional `patches` or `overlay`.
    - `presubmit.yml`: CI configuration (platforms, build/test targets).
    - `patches/`: `.patch` files to modify upstream source.
    - `overlay/`: Files to add or overwrite in the upstream source.

## ⚖️ Important Policies
- **Add-only**: The BCR is immutable. Never modify an existing version.
- **Registry Fixes**: If a fix is registry-only (e.g., fixing compatibility with a new Bazel version), append `.bcr.<N>` to the version (e.g., `1.2.3` -> `1.2.3.bcr.1`).
- **Bazel 9 Compatibility**: Native rules (like `cc_library`) are being removed.
    - Add `bazel_dep(name = "rules_cc", version = "...")` to `MODULE.bazel`.
    - Use `load("@rules_cc//cc:defs.bzl", "cc_library", ...)` in `BUILD` files via patches.
- **Overlays**: When using `overlay/`, include `bazel_compatibility = [">=7.2.1"]` in `MODULE.bazel`.
- **Target Names**: C++ modules should ideally expose a target with the same name as the module to allow `@module_name` syntax.

## 🛠️ Essential Tools
- `//tools:add_module`: Interactive scaffolding.
- `//tools:update_integrity`: SHA-256 automation.
- `//tools:bcr_validation`: Local CI check.
- `//tools:setup_presubmit_repos`: Local build reproduction.
