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
- [ ] Prefer adding a **test module** and/or **anonymous module** verify targets;
- [ ] Encourage to build everything from source (no prebuilt binaries) unless absolutely necessary. Registering prebuilt toolchains is a common and acceptable exception.

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

### Versioning

- BCR is **add-only**: never mutate an existing published version. To fix issues found only in BCR patches, add a new version with a `.bcr.N` suffix.
- Pseudo-versions allowed (e.g. `1.19.1-YYYYMMDDHHMMSS-abcdef`) when upstream is stale.

### Source

- You can ignore reviewing the `source.json` file as it will be tested in presubmit.

### Presubmit & Validations

- `presubmit.yml` is required for each version. Anonymous-module tasks should be put under the top-level `tasks` key, and test-module tasks under `bcr_test_module.tasks`. `tasks` should not be specified anywhere else because they will be ignored.
- Each task must specify at least one of `build_targets` or `test_targets`, but not necessarily both.

### Metadata

- `metadata.json.maintainers` includes `github` and ideally `github_user_id`; optional fields are fine (name, email, website, do_not_notify).
- Gemini should ping @bazelbuild/bcr-maintainers for a manual review if there are any significant changes (ignoring reformatting) to the `maintainers` or `repository` fields in `metadata.json` files.

### MODULE.bazel

- The MODULE.bazel file may contain overrides (e.g. `archive_override`, `git_override`, `local_path_override`). Those will be ignored when the module is used as a dependency, so they are allowed and you can ignore reviewing them.
- The MODULE.bazel file may contain dev dependencies specified with `dev_dependency = True`. Dev dependencies are ignored when the module is used as a dependency, so they are allowed and you can ignore reviewing them.
- Modules may not contain symlinks. That includes `MODULE.bazel` files in modules' `overlay/` sub-directories.
- Bazel module resolution allows cyclic dependencies.
- Do not comment on or check if the version of a `bazel_dep` is correct; this will be covered by presubmit.

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
