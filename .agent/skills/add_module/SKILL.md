---
name: add-module
description: >-
  Creates module directories and initializes configuration files for a new module version in the Bazel Central Registry (BCR). Use when scaffolding a new version of a module, setting up MODULE.bazel, source.json, and presubmit.yml, or updating module metadata.json files.
---

# Add Module

This skill provides the exact procedure for scaffolding a new module version in the Bazel Central Registry (BCR).

## Prerequisites
Make sure you are at the root of the `bazel-central-registry` repository.

## Procedure

Copy this checklist and track progress:
- [ ] Step 1: Create the version directory under `modules/{module_name}/{version}`
- [ ] Step 2: Copy `MODULE.bazel`, `source.json`, and `presubmit.yml` from a previous version
- [ ] Step 3: Update the new version entry in `modules/{module_name}/metadata.json`

### 1. Create Directory
```bash
mkdir -p modules/{module_name}/{version}
```

### 2. Initialize Files
Copy `MODULE.bazel`, `source.json`, and `presubmit.yml` from a previous version to the newly created directory. Update version info as needed.

### 3. Update Metadata
Add the new version to `modules/{module_name}/metadata.json`.
