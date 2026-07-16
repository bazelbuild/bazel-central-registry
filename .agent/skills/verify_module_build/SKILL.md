---
name: verify-module-build
description: >-
  Sets up and verifies local presubmit repository builds for modules in the Bazel Central Registry (BCR). Use when reproducing presubmit builds, testing module dependencies locally.
---

# Verify Module Build

This skill provides instructions for setting up and verifying module builds locally in the Bazel Central Registry (BCR).

## Procedure

Copy this checklist and track progress:
- [ ] Step 1: Setup presubmit repositories
- [ ] Step 2: Run tests
- [ ] Step 3: Troubleshoot stale cache if necessary

### 1. Setup
Prepare the local repositories for the module version:
```bash
bazel run //tools:setup_presubmit_repos -- --module {module_name}@{version}
```

### 2. Test
Run the specific build or test command provided by the setup tool's output.

### 3. Troubleshoot
If local changes are not reflected during testing, clear the bazel cache:
```bash
bazel clean --expunge
```
