---
description: Verify module build locally
---
1. **Setup**:
   ```sh
   bazel run //tools:setup_presubmit_repos -- --module <name>@<version>
   ```
2. **Test**: Run the build command provided by the setup tool's output.
3. **Troubleshoot**: Use `bazel clean --expunge` if changes are not reflected.
