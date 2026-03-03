---
description: Validate and iterate on a module version
---

1. **Validate**:
   ```sh
   bazel run //tools:bcr_validation -- --check <name>@<version>
   ```
2. **Update Integrity**:
   ```sh
   bazel run //tools:update_integrity -- <name> --version=<version>
   ```
3. **Overlay vs Patches**:
   - `overlay/`: Add or overwrite files (requires `bazel_compatibility` in `MODULE.bazel`).
   - `patches/`: Modify existing files.
4. **Consistency**: `modules/.../MODULE.bazel` must match the source archive's version (if exists) exactly. Use an overlay/patch if they differ.