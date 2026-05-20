---
name: validate-module
description: >-
  Validates module configuration and updates source integrity in the Bazel Central Registry (BCR). Use when running bcr_validation checks, updating integrity with update_integrity, or verifying overlay and patch consistency for module versions.
---

# Validate Module

This skill provides the exact procedure for validating and iterating on a module version in the Bazel Central Registry (BCR).

## Procedure

Copy this checklist and track progress:
- [ ] Step 1: Run validation checks
- [ ] Step 2: Update source integrity
- [ ] Step 3: Check overlay and patch consistency

### 1. Validate
Run the local BCR validation tool:
```bash
bazel run //tools:bcr_validation -- --check {module_name}@{version}
```

### 2. Update Integrity
Generate or update the SHA-256 integrity hash:
```bash
bazel run //tools:update_integrity -- {module_name} --version={version}
```

### 3. Overlay vs Patches
- **overlay/**: Add or overwrite files. Requires `bazel_compatibility >= 7.2.1` in `MODULE.bazel`.
- **patches/**: Modify existing upstream source files using `.patch` files.
- **README.md**: Add a README.md if the purpose of overlay or patch files are
  not obvious.

### 4. Consistency Check
- If the source archive doesn't contain a MODULE.bazel, `modules/{module_name}/{version}/MODULE.bazel` should not exist.
- Otherwise, ensure that `modules/{module_name}/{version}/MODULE.bazel` matches the source archive's version exactly. Use an overlay or patch if they differ.
