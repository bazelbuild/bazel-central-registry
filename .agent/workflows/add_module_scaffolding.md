---
description: Scaffolding for a new module version in the BCR
---
1. **Create Directory**:
   ```sh
   mkdir -p modules/<name>/<version>
   ```
2. **Initialize Files**: Copy `MODULE.bazel`, `source.json`, and `presubmit.yml` from a previous version.
3. **Update Metadata**: Add the new version to `modules/<name>/metadata.json`.
