# bazeldnf BCR Module Notes

## Release Tarball vs GitHub Raw File

The release tarball at `https://github.com/rmohr/bazeldnf/releases/download/<version>/bazeldnf-<version>.tar.gz`
differs from the raw tag file at `https://raw.githubusercontent.com/rmohr/bazeldnf/<version>/MODULE.bazel`.

**Always download and inspect the actual tarball** before writing the patch:
```sh
curl -sL <tarball-url> | tar xzO bazeldnf-<version>/MODULE.bazel | cat -n
```

The tarball's `MODULE.bazel`:
- Starts with `"bazelndf dependencies"` as line 1 (a string literal — not a comment)
- Has the correct version already set (e.g. `version = "v0.99.2-rc1"`)

## What the Patch Does

The patch removes non-dev Go build tool dependencies that are not needed by consumers:
- `bazel_dep(name = "gazelle", ...)`
- `bazel_dep(name = "rules_go", ...)`
- `go_sdk` extension block
- `go_deps` extension block and `use_repo`

Dev dependencies marked with `dev_dependency = True` (e.g. `bazeldnf_dev`, `protobuf`, build tools)
do NOT need to be patched out — Bazel ignores them for consumers.

## Patch Format

Use git-style `a/b` headers with `patch_strip=1` in `source.json`:
```diff
--- a/MODULE.bazel
+++ b/MODULE.bazel
```

**Not** the `MODULE.bazel.orig` / `MODULE.bazel` format (patch_strip=0) used in rc0 — that format
requires `MODULE.bazel.orig` to exist in the tarball, which it doesn't.

## MODULE.bazel.orig

The `modules/bazeldnf/v0.99.2-rc0/MODULE.bazel.orig` file should not be in the repo.
Do not carry it over when creating new versions.

## Adding a New Version — Checklist

1. `mkdir -p modules/bazeldnf/<version>` and copy from previous version
2. Delete `MODULE.bazel.orig` if copied
3. Download and inspect the actual tarball's `MODULE.bazel`
4. Update `MODULE.bazel` to match the tarball's kept content (with Go deps removed)
5. Update `patches/MODULE.bazel.patch` as a diff from tarball → BCR MODULE.bazel
6. Update `source.json`: new URL, `docs_url`, `strip_prefix`, `patch_strip: 1`, placeholder integrity hashes
   - `docs_url` format: `https://github.com/rmohr/bazeldnf/releases/download/<version>/bazeldnf-<version>.docs.tar.gz`
7. Add new version to `metadata.json`
8. Run `bazel run //tools:update_integrity -- bazeldnf --version=<version>`
9. Run `bazel run //tools:bcr_validation -- --check bazeldnf@<version>`
10. Commit with message format:
    ```
    bazeldnf@<version>

    Release: https://github.com/rmohr/bazeldnf/releases/tag/<version>

    This commit was made with the help of Claude (claude.ai)
    ```

    Note: do NOT use `Co-Authored-By: Claude ...` — Anthropic would need to sign Google's CLA.
