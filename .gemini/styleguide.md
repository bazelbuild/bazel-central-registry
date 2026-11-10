# BCR PR Review Style Guide (for Gemini Code Assistant)

Gemini Code Assistant acting as a reviewer-helper for PRs to the **Bazel Central Registry (BCR)**.

**Goals:** Ensure PRs follow BCR policies, stay “add‑only,” are secure, reproducible, and easy for downstream users.

---

## 0) TL;DR – One‑Screen Checklist

**Gatekeepers (block PR if any fail):**

- [ ] **Add‑only:** PR doesn’t mutate existing module versions (except allowed `presubmit.yml`/`README.md` updates) or bundle unrelated non‑module files when adding a version.
- [ ] **Required files present and valid:** `modules/<name>/metadata.json`, `modules/<name>/<version>/{MODULE.bazel, source.json, presubmit.yml}`.
- [ ] **Maintainer entries & no symlinks:** Every maintainer entry with `github` also sets `github_user_id`; module directories contain no symlinks.

**Strong suggestions (ask for changes, but not always blockers):**

- [ ] **Module naming (new modules):** Name is succinct and unambiguous; avoid overly generic names (e.g., `package-utils` -> `<user_or_org>-package-utils`) or misleading `rules_`/`toolchains_` prefixes that duplicate well-established official rulesets.
- [ ] **Module maintainership:** If a module has no existing maintainers (including new modules), encourage the PR author to add themselves to `metadata.json.maintainers`.
- [ ] **C++ patches/overlays target & visibility:** Expose a public target named after the module (or for `libfoo`, target `foo` with alias `libfoo` -> `foo`) so `@<module>` shorthand works; ensure intended public APIs have `//visibility:public` while keeping the set of public targets small.
- [ ] **Overlays:** Include `bazel_compatibility` >= 7.2.1 in `MODULE.bazel` and brief notes (in `README.md` or `BUILD` comments) on how large `BUILD` overlays were created.
- [ ] **Presubmit config:** Prefer adding a **test module** and/or **anonymous module** verify targets; encourage including the latest Bazel LTS track in `presubmit.yml`; carefully review any `presubmit.yml` changes beyond platform names or Bazel versions before `presubmit-auto-run` is applied.
- [ ] **Build from source:** Encourage building everything from source (no prebuilt binaries) unless absolutely necessary. Registering prebuilt toolchains is a common and acceptable exception.

---

## 1) What “Good” Looks Like

### Structure

```
modules/
  <module_name>/
    metadata.json
    README.md (optional: e.g., document BUILD overlays)
    <version>/
      MODULE.bazel
      source.json
      presubmit.yml
      # optional:
      patches/*.patch
      overlay/**/*
      README.md
```

### Module Naming (New Modules)

- When a PR adds an entirely new module to the BCR, perform a sanity check on its name:
  - Ideally, the name is succinct and unambiguous. Overly generic names (e.g., `package-utils`) should be avoided unless the project is well-known in the developer community; suggest prepending the user or org name (e.g., `mycompany-package-utils`).
  - Minimize potential user confusion from a module not doing what the name suggests or duplicating well-established, existing options in the BCR.
  - Watch out for official-sounding prefixes such as `rules_` or `toolchains_` that merely wrap or duplicate a well-maintained official ruleset (for example, `rules_objc` wrapping `rules_cc`, which already covers Objective-C). Suggest prepending the user or org name (e.g., `mycompany_rules_objc`).

### Versioning

- BCR is **add-only**: never mutate an existing published version. To fix issues found only in BCR patches, add a new version with a `.bcr.N` suffix.
- Pseudo-versions allowed (e.g. `1.19.1-YYYYMMDDHHMMSS-abcdef`) when upstream is stale.

### Source

- You can ignore reviewing the `source.json` file as it will be tested in presubmit.

### Overlays & C++ `BUILD` Files

- When a module version uses `overlay/`, `MODULE.bazel` must include `bazel_compatibility` of at least `>=7.2.1`.
- When a PR contains C++ modules with `BUILD` patches or overlays:
  - Encourage exposing a primary build target with the same name as the module itself (enabling the shorthand label `@foo` for `@foo//:foo`).
  - For modules whose name starts with `lib` (for example, `libfoo`), ask for a target named `foo` with an `alias` named `libfoo` pointing to `foo`.
  - Double-check visibility specifications: authors often forget `//visibility:public` on intended public targets (which is not caught unless `presubmit.yml` has a test module), while internal targets should remain private to keep the set of publicly visible targets small.
  - For large `BUILD` overlays, ask for brief documentation on how the `BUILD` files were created/generated (either in a `README.md` under the module directory or as comments in the `BUILD` overlays).

### Presubmit & Validations

- `presubmit.yml` is required for each version. Anonymous-module tasks should be put under the top-level `tasks` key, and test-module tasks under `bcr_test_module.tasks`. `tasks` should not be specified anywhere else because they will be ignored.
- Each task must specify at least one of `build_targets` or `test_targets`, but not necessarily both.
- When `presubmit.yml` changes compared to the previous version (beyond just platform names or `bazel` versions), CI checks are blocked until a BCR maintainer reviews those changes and applies the `presubmit-auto-run` label. Carefully inspect what changed in `presubmit.yml` relative to the previous version.
- If possible, encourage PR authors to include the latest Bazel LTS track in the `bazel` field in `presubmit.yml`.

### Metadata & Maintainership

- Each maintainer entry in `metadata.json.maintainers` with a `github` handle must also include `github_user_id`; optional fields are fine (name, email, website, do_not_notify).
- When a PR adds to a module with no existing maintainers (including when the module is new), encourage the PR author to take on module maintainership in `metadata.json.maintainers` (since modules with no maintainers always require BCR maintainer review, adding to response times and toil).
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
