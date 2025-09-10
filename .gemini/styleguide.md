# BCR PR Review Style Guide (for Gemini Code Assistant)

Gemini Code Assistant acting as a reviewer-helper for PRs to the **Bazel Central Registry (BCR)**.

**Goals:** Ensure PRs follow BCR policies, stay “add‑only,” are secure, reproducible, and easy for downstream users.

---

## 0) TL;DR – One‑Screen Checklist

**Gatekeepers (block PR if any fail):**
- [ ] **Add‑only:** PR doesn’t mutate existing module versions or non‑module files when adding a version.
- [ ] **Required files present and valid:** `modules/<name>/metadata.json`, `modules/<name>/<version>/{MODULE.bazel, source.json, presubmit.yml}`.
- [ ] **Maintainers listed:** `metadata.json.maintainers` includes at least one GitHub handle.

**Strong suggestions (ask for changes, but not always blockers):**
- [ ] Module name is specific and unambiguous (avoid overly generic names).
- [ ] For C++ overlays: ensure a public target named after the module (or alias `libfoo` -> `foo`); visibility is minimal but includes `//visibility:public` for intended APIs.
- [ ] If using overlays: include `bazel_compatibility` >= 7.2.1 and brief notes on how large BUILD overlays were created.
- [ ] Prefer adding a **test module** and/or **anonymous module** verify targets; keep `test_targets` realistic.
- [ ] Encourage to build everything from source (no prebuilt binaries) unless absolutely necessary.

---

## 1) What “Good” Looks Like

### Structure
```
modules/
  <module_name>/
    metadata.json
    <version>/
      MODULE.bazel
      source.json
      presubmit.yml
      # optional:
      patches/*.patch
      overlays/**/*
      README.md (e.g., document BUILD overlays)
```
**Notes**
- `source.json.type` must be `archive` (default) or `git_repository` — not `local_path`.
- `metadata.json.maintainers` includes `github` and ideally `github_user_id`; optional fields are fine (name, email, website, do_not_notify).

### Versioning
- BCR is **add-only**: never mutate an existing published version. To fix issues found only in BCR patches, add a new version with a `.bcr.N` suffix.
- Pseudo-versions allowed (e.g. `1.19.1-YYYYMMDDHHMMSS-abcdef`) when upstream is stale.

### Presubmit & Validations
- `presubmit.yml` is required for each version. Anonymous-module tasks should be put under the top-level `tasks` key, and test-module tasks under `bcr_test_module.tasks`. `tasks` should not be specified anywhere else because they will be ignored.

### Metadata

- If there is non-trivial changes to `metadata.json` files, please ping `@bazelbuild/bcr-maintainers` for a manual review.

---

## 2) Handy References & Commands (for authors)

- Validate locally: `bazel run -- //tools:bcr_validation --check=<name>@<version>`
- Update integrity: `bazel run -- //tools:update_integrity <name>`
- Reproduce presubmit repos: `bazel run -- //tools:setup_presubmit_repos --module @<name>`
- Test with local registry:
  ```bash
  bazel shutdown && bazel build --enable_bzlmod \
    --registry="file:///path/to/bazel-central-registry" \
    --lockfile_mode=off @<module>//:<target>
  ```

## 3) Additional Notes

- There could be symlinks under `overlay/` directory that points to a `MODULE.bazel` file in the parent directory. The file content of the symlink will look like `../MODULE.bazel`, these are allowed.
