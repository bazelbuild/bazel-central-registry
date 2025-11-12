# Bazel Central Registry (BCR) contribution guidelines

Before contributing to the Bazel Central Registry, check the [BCR policies](bcr-policies.md) to learn how the BCR is maintained.

## Structure

The BCR follows the format of a regular [Bazel registry](https://bazel.build/external/registry), with some additional requirements:

- Extra metadata.json fields (see [JSON schema](https://github.com/bazelbuild/bazel-central-registry/blob/main/metadata.schema.json)):
  - `maintainers`: an array of JSON objects, each representing a module maintainer. Each object can have the following fields:
    - `github`: a string, the maintainer's GitHub username. This is used to `@`-ping the maintainer when a PR updating the module is sent, and determines whether a GitHub user has approval rights for a PR (see [approval and submission](#approval-and-submission) below).
    - `github_user_id`: a number, the maintainer's GitHub ID number. This is used to verify the maintainer's identity in case of GitHub username change or deletion. Run `bazel run //tools:bcr_validation -- --check_metadata=foo --fix` to update it for the module `foo`.
    - `name`: a string, the maintainer's name. Purely informational.
    - `email`: a string, the maintainer's email address. Purely informational.
    - `do_not_notify`: a boolean. When set to `true`, the maintainer will still have approval rights, but will not be `@`-pinged when a PR for the module is sent.
  - `website`: a string, the URL of the project's website. Purely informational.
  - `repository`: an array of strings. This is an allowlist of source URLs; the source URL in the `source.json` file must match at least one of the entries here.
    - If the string has the format of `github:<org>/<repo>`, then source URLs from `https://github.com/<org>/<repo>` are allowed (see the [validations](#validations) section below).
    - If the string has the format of a regular URL (such as `https://foo.com/bar`), then source URLs beginning with the string are allowed. The string can optionally end in a slash (`/`), with no difference in the semantics (for example, `https://foo.com/bar/thing.zip` would be accepted, but `https://foo.com/barthing.zip` would not).
  - `deprecated`: a string. When set, this denotes that the module should not be used. Must be set if the module's latest version is [yanked](#yank-a-module-version).
- The `source.json` file must be of the `type` `archive` (which is the default) or `git_repository`. Other types such as `local_path` are not allowed.
- A presubmit.yml file. See [Presubmit](#presubmit) below.

## Contribute a Bazel module

To contribute a new module or a new version to an existing module, you can clone the BCR repository and run the interactive helper script:

```bash
git clone https://github.com/bazelbuild/bazel-central-registry.git
cd bazel-central-registry
bazel run //tools:add_module
```

The script will generate all required changes based on your input, please review, modify and commit the change, then send a PR to the BCR repository.

If you are the project owner, you can set up the [Publish to BCR](https://github.com/apps/publish-to-bcr) Github App for your repository to automatically send a PR to the BCR when cutting a new release.

When manually editing files you may find `bazel run -- //tools:update_integrity foomod` useful to update the integrity hashes in foomod's source.json file.
The tool also accepts a `--version` option to update the `source.json` of a specific version of the module (instead of latest).

### Testing your change locally

1. Clone BCR locally with `git clone git@github.com:bazelbuild/bazel-central-registry.git`
2. Make the changes you want to BCR. Make use of `bazel run //tools:add_module` and `bazel run //tools:update_integrity` etc.
3. Update your `MODULE.bazel` file in your repository you want to use the change made in step 2.
4. To test the changes, in your own repo that consumes the BCR Module you added, run:

   ```bash
   bazel shutdown && bazel build --enable_bzlmod --registry="file:///path/to/bazel-central-registry" --lockfile_mode=off @module-to-build//:target
   # the target can also be your target that depends on this.
   ```

### Documenting the module

The `source.json` permits a `docs_url` attribute pointing to the documentation.

This may optionally point to an archive file of stardoc_output.proto files, see [Stardoc API Docs](./stardoc.md).

## Presubmit

Every module version must pass the BCR presubmit before getting merged. The presubmit validates the correctness and consistency of module information, then runs build and test targets specified in the `presubmit.yml` file. The BCR presubmit is driven by the [bcr_presubmit.py](https://github.com/bazelbuild/continuous-integration/blob/master/buildkite/bazel-central-registry/bcr_presubmit.py) script on [Bazel CI](https://github.com/bazelbuild/continuous-integration/tree/master/buildkite#bazel-continuous-integration).

### Validations

Most of presubmit validations are implemented in `./tools/bcr_validation.py`. So you can also run the following command to validate a module locally:

```bash
bazel run -- //tools:bcr_validation --check=foo@1.0.0
```

Validations performed in the scripts are:

- Verify the module version exists in the `metadata.json` of the module.
- Verify the source archive URL matches the source repository specified in `metadata.json`.
- Verify the source archive URL is stable if it comes from GitHub. (See [this discussion](https://github.com/bazel-contrib/SIG-rules-authors/issues/11#issuecomment-1029861300)). Comment `@bazel-io skip_check unstable_url` to skip this check.
- Verify the integrity values of the source archive and patch files (if any) are correct.
- Verify the checked-in `MODULE.bazel` file matches the one in the extracted and patched source tree.
- Verify the `compatibility_level` in `MODULE.bazel` matches the previous version. If the bump is intentional, you can comment `@bazel-io skip_check compatibility_level` in the PR to skip this check.
- Check if the module is new or the `presubmit.yml` file is changed compared to the last version, if so a BCR maintainer review will be required to run jobs specified in `presubmit.yml`.

Additional validations implemented in the [bcr_presubmit.py](https://github.com/bazelbuild/continuous-integration/blob/master/buildkite/bazel-central-registry/bcr_presubmit.py) script:

- The checked-in `MODULE.bazel`, `source.json`, patches files are not modified in the PR.
- The files outside of `modules/` directory are not modified in the pull request if the PR is adding a new module version.

### Anonymous module test

The modules in the BCR are meant to be used as dependencies of other Bazel modules. You can specify the targets you want to expose for your dependents in the `presubmit.yml` file, and the BCR presubmit will verify those targets can be built correctly when used as dependencies of a simple anonymous module.

For example, in `zlib@1.2.13`'s [presubmit.yml](https://github.com/bazelbuild/bazel-central-registry/blob/main/modules/zlib/1.2.13/presubmit.yml#L13):

```yaml
matrix:
  platform:
  - rockylinux8
  - debian10
  - ubuntu2004
  - macos
  - windows
  bazel: [6.x, 7.x]
tasks:
  verify_targets:
    name: Verify build targets
    platform: ${{ platform }}
    bazel: ${{ bazel }}
    build_targets:
    - '@zlib//:zlib'
```

In the presubmit, a simple anonymous module will be created with `MODULE.bazel`:

```python
bazel_dep(name="zlib", version="1.2.13")
```

Then the presubmit will verify building `@zlib//:zlib` succeeds on all specified platforms.

While you can also specify `test_targets`, it may not always work since test targets can require additional dev dependencies that are not available when your project is not the root module.

**Note that** the task config syntax follows [Bazel CI's specifications](https://github.com/bazelbuild/continuous-integration/tree/master/buildkite#configuring-a-pipeline). BCR requires the bazel version to be specified for each task via the `bazel` field.

### Test module

It's **highly recommended** to specify a test module that includes example usages of your module, which will help verify the basic APIs and functionalities of your module work correctly.

A test module is located in a subdirectory of the extracted and patched source tree of the target module (the module you want to check in). You can specify the tasks in the `presubmit.yml` file under `bcr_test_module`. A `MODULE.bazel` file should be in the test module directory, and it can depend on the target module with `local_path_override`. With the test module, you can introduce additional dependencies for testing without affecting the target module.

For example, in `rules_jvm_external@4.4.1`'s [presubmit.yml](https://github.com/bazelbuild/bazel-central-registry/blob/main/modules/rules_jvm_external/4.4.2/presubmit.yml) file:

```yaml
bcr_test_module:
  module_path: examples/bzlmod
  matrix:
    platform:
    - rockylinux8
    - debian10
    - ubuntu2004
    - macos
    - windows
    bazel: [6.x, 7.x]
  tasks:
    run_test_module:
      name: Run test module
      platform: ${{ platform }}
      bazel: ${{ bazel }}
      build_targets:
      - //java/src/com/github/rules_jvm_external/examples/bzlmod:bzlmod_example
```

In `rules_jvm_external`'s [example/bzlmod/MODULE.bazel](https://github.com/bazelbuild/rules_jvm_external/blob/853c82772671fa4ac119c211011af5dc03b383f1/examples/bzlmod/MODULE.bazel#L6-L11):

```python
bazel_dep(name = "rules_jvm_external")
local_path_override(
    module_name = "rules_jvm_external",
    path = "../..",
)
```

**Note that** the task config syntax also follows [Bazel CI's specifications](https://github.com/bazelbuild/continuous-integration/tree/master/buildkite#configuring-a-pipeline), but just one level deeper under `bcr_test_module` and you have to specify the subdirectory of the test module via `module_path`. BCR requires the bazel version to be specified for each task via the `bazel` field.

### Reproduce presubmit builds locally

You can reproduce the presubmit environment locally by running the following command:

```bash
bazel run //tools:setup_presubmit_repos -- --module <module_name>@<version>
```

Then follow the instructions to run the build locally.

### Testing incompatible flags

Major breaking changes in Bazel are guarded by [incompatible flags](https://bazel.build/release/backward-compatibility). To assist the community with migration, BCR presubmit tests new modules against these flags using Bazelisk's [--migrate](https://github.com/bazelbuild/bazelisk/tree/master?tab=readme-ov-file#--migrate) feature, providing module maintainers with early warnings.

By default, the flags tested are fetched from [incompatible_flag.yml](/incompatible_flags.yml), but they can be overridden in the `presubmit.yml` file for a specific module version.

In the YAML files, you can specify a top-level `incompatible_flags` field in the format of:

```yaml
incompatible_flags:
  "--incompatible_config_setting_private_default_visibility":
    - 6.x
    - 7.x
    - 8.x
  "--incompatible_autoload_externally=":
    - 7.x
    - 8.x
```

During presubmit jobs, flags matching the current Bazel version in use will be tested. This applies to both the [anonymous module](#anonymous-module-test) and the [test module](#test-module).

If you need to temporarily skip incompatible flags testing, you can comment `@bazel-io skip_check incompatible_flags` in your PR. This will automatically add the `skip-incompatible-flags-test` label to the PR, bypassing incompatible flags testing for all presubmit jobs. You can migrate for those breaking changes at a later time.

For an overview result of testing top BCR modules with incompatible flags, you can check the nightly build of [BCR Bazel Compatibility Test](https://buildkite.com/bazel/bcr-bazel-compatibility-test).

Before adding a flag in [incompatible_flag.yml](/incompatible_flags.yml), please make sure the most commonly used modules are fixed, otherwise migration for other modules will be blocked without any workaround.

## Approval and submission

To be submitted, a PR needs to:

- Be approved by a module maintainer and/or a BCR maintainer
  - When a PR is opened, the `bazel-io` bot will `@`-ping all module maintainers (who do not have `do_not_notify` set) and ask for a review.
  - Note that a module maintainer can approve a PR by using the normal GitHub PR review flow, despite not having write access to the git repository; the `bazel-io` bot account will approve the PR for merge later.
- Pass [presubmit](#presubmit) checks
  - If you see your presubmit check stuck on "blocked", a BCR maintainer needs to explicitly unblock the presubmit run or apply the `presubmit-auto-run` label to your PR. This is to avoid abuse of our CI system. Feel free to ping `@bazelbuild/bcr-maintainers` if you're blocked on this.
- Pass certain other checks, especially for first-time contributors, such as CLA signing or GitHub workflows that require approval from BCR maintainers.

In case a release is broken, the PR to publish it may never be merged.
Module maintainers can ask the `bazel-io` bot to close a PR by commenting `@bazel-io abandon` on the PR thread.
This is intended for cases where the PR is opened by a bot account, and helps BCR maintainers keep the PR backlog manageable.

## Module versions

Bazel has a diverse ecosystem, and projects use a variety of versioning schemes. Bazel modules have a fairly relaxed [version format](https://bazel.build/external/module#version_format), which covers most version strings used by open-source projects. Thus, modules submitted to the BCR are generally versioned according to their upstream project's versions.

### Add-only

To ensure reproducibility, the BCR is add-only; that is, existing versions of a module cannot be modified. If an existing module version needs a fix, it should be fixed upstream and a new version can be submitted. If, however, the fix is only in patch files present in BCR (as in, there is nothing to fix upstream), the convention is to append a `.bcr.<N>` suffix for the new version. For example, if `foo` version `1.2.3` needs patches to fix a problem, you can submit a new version `1.2.3.bcr.1`.

### Pseudo-versions

If upstream hasn't released a new version in a long time (for example, due to project owner inactivity), but you'd still like to submit a version based on a main branch commit, the convention is to use a [pseudo-version](https://go.dev/ref/mod#pseudo-versions) similar to the one in the Go module system. Unlike in Go, such pseudo-versions are not semantically significant; they're just treated normally as any other version string. For example, if `foo`'s current version is `1.19.0`, you can submit a new version `1.19.1-20250305-abcdef`. This can also be combined with the `.bcr.<N>` suffix if necessary.

### Yank a module version

If a module version is discovered with security vulnerabilities or for any reason should no longer be used, you can yank the module version by adding it to the `yanked` map in `metadata.json` and provide a reason.

For example, in `zlib`'s [metadata.json](https://github.com/bazelbuild/bazel-central-registry/blob/b842554be071a180d78c3a936c8ee0c94c74e8bd/modules/zlib/metadata.json#L17):

```json
"yanked_versions": {
    "1.2.11": "CVE-2018-25032 (https://github.com/advisories/GHSA-jc36-42cf-vqwj)",
    "1.2.12": "CVE-2022-37434 (https://github.com/advisories/GHSA-cfmr-vrgj-vqwv)"
}
```

A Bzlmod user's build will start to fail if the yanked version is in the resolved dependency graph, and the yanked reason will be presented in the error message. The user can choose to upgrade the dependency or they can bypass the check by specifying the `--allow_yanked_versions` flag or the `BZLMOD_ALLOW_YANKED_VERSIONS` environment variable. Check [the documentation](https://bazel.build/reference/command-line-reference#flag--allow_yanked_versions) to learn how to use them.

The latest version of a module should not be yanked. If you do need to yank the latest version because the module is deprecated, you should add `"deprecated": "<reason>"` in its `metadata.json` file.

### Requesting to take down a module

If for any reason, you think a module or a version of a module should be removed from the Bazel Central Registry, please [file a bug](https://github.com/bazelbuild/bazel-central-registry/issues/new?assignees=&labels=bug&template=bug.yaml&title=%5BBug%5D%3A+) and reach out to BCR maintainers at bcr-maintainers@bazel.build.
