# Gemini's Guide to Adding a Module to the Bazel Central Registry

This document summarizes the key learnings from adding a new module version to the Bazel Central Registry (BCR).

## 1. Initial Scaffolding

1.  **Create the version directory**:
    ```sh
    mkdir -p modules/<module_name>/<version>
    ```
2.  **Create the `MODULE.bazel` file**: Copy from a previous version if possible and update the version number. If the module has dependencies, ensure they are correctly listed.
3.  **Create the `source.json` file**: Copy from a previous version if possible and update the version number. This file contains the URL of the source archive, its integrity hash, and the `strip_prefix`. If the source archive doesn't contain a `MODULE.bazel` or `BUILD.bazel` file, you'll need to provide them in an `overlay`.
4.  **Create `overlay` and `patches` directories**: If the module requires any overlays or patches, copy these directories from a previous version if they exist.
5.  **Create `presubmit.yml`**: The validation script will fail if `modules/<module_name>/<version>/presubmit.yml` does not exist. You can usually copy this file from a previous version.
6.  **Update `metadata.json`**: The validation script will fail if the new version is not added to the `versions` list in `modules/<module_name>/metadata.json`.

## 2. Validation and Iteration

*   **Validation is your best friend**: The `tools/bcr_validation.py` script is the most important tool for this process. Run it early and often. Use the `--check` flag to specify the module and version you are working on: `bazel run //tools:bcr_validation -- --check <module_name>@<version>`.
*   **Use the `update_integrity` tool**: The `bazel run //tools:update_integrity -- <module name> --version=<version>` command is the correct way to update the integrity hashes in `source.json`.
*   **`overlay` vs. `patches`**:
    *   `overlay`: Use this to add or overwrite files in the downloaded source archive. The files to be overlaid should be placed in an `overlay` subdirectory within the version directory.
    *   `patches`: Use this to apply changes to existing files in the source archive. Patch files should be placed in a `patches` subdirectory.
*   **`MODULE.bazel` Duplication**: The `MODULE.bazel` file must exist in two places:
    1.  At the root of the version directory (`modules/<module_name>/<version>/MODULE.bazel`).
    2.  Inside the `overlay` directory (`modules/<module_name>/<version>/overlay/MODULE.bazel`). The file in the `overlay` directory should be a symlink to the one at the root.
*   **`bazel_compatibility`**: When using `overlay`, the `MODULE.bazel` file must specify the `bazel_compatibility` attribute.

## 3. Build Verification

*   **Use the presubmit setup tool**: The `bazel run //tools:setup_presubmit_repos -- --module <module_name>@<version>` command sets up a local test environment.
*   **Run the local build**: The output of the presubmit setup tool provides the exact `bazel build` command to run for local testing.
*   **Clear the caches**: If you are having trouble with changes not being picked up, run `bazel clean --expunge` to clear the caches.
