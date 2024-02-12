# Bazel Central Registry (BCR) contribution guidelines

Before contributing to the Bazel Central Registry, check the [BCR policies](bcr-policies.md) to learn how the BCR is maintained.

## Contribute a Bazel module

To contribute a new module or a new version to an existing module, you can clone the BCR repository and run the interactive helper script:

```bash
git clone https://github.com/bazelbuild/bazel-central-registry.git
cd bazel-central-registry
bazel run //tools:add_module
```

The script will generate all require changes based on your input, please review, modify and commit the change, then send a PR to the BCR repository.

If you are the project owner, you can set up the [Publish to BCR](https://github.com/apps/publish-to-bcr) Github App for your repository to automatically send a PR to the BCR when cutting a new release.

When manually editing files you may find `bazel run -- //tools:update_integrity foomod` useful to update the integrity hashes in foomod's source.json file.
The tool also accepts a `--version` option to update the source.json of a specific version of the module (instead of latest).

## Presubmit

Every module version must pass the BCR presubmit before getting merged. The presubmit validates the correctness and consistency of module information, then runs build and test targets specified in the `presubmit.yml` file. The BCR presubmit is driven by the [bcr_presubmit.py](https://github.com/bazelbuild/continuous-integration/blob/master/buildkite/bazel-central-registry/bcr_presubmit.py) script on [Bazel CI](https://github.com/bazelbuild/continuous-integration/tree/master/buildkite#bazel-continuous-integration).

### Validations

Most of presubmit validations are implemented in `./tools/bcr_validation.py`. So you can also run the following command to validate a module locally:

```bash
python3 tools/bcr_validation.py --check=foo@1.0.0
```

Validations performed in the scripts are:

- Verify the module version exists in the `metadata.json` of the module.
- Verify the source archive URL matches the source repository specified in `metadata.json`.
- Verify the source archive URL is stable if it comes from GitHub. (See [this discussion](https://github.com/bazel-contrib/SIG-rules-authors/issues/11#issuecomment-1029861300))
- Verify the integrity values of the source archive and patch files (if any) are correct.
- Verify the checked-in MODULE.bazel file matches the one in the extracted and patched source tree.
- Check if the module is new or the `presubmit.yml` file is changed compared to the last version, if so a BCR maintainer review will be required to run jobs specified in `presubmit.yml`.

Additional validations implemented in the [bcr_presubmit.py](https://github.com/bazelbuild/continuous-integration/blob/master/buildkite/bazel-central-registry/bcr_presubmit.py) script:

- The checked-in MODULE.bazel, source.json, patches files are not modified in the PR.
- The files outside of `modules/` directory are not modified in the pull request if the PR is adding a new module version.

### Anonymous module test

The modules in the BCR are meant to be used as dependencies of other Bazel modules. You can specify the targets you want to expose for your dependents in the `presubmit.yml` file, and the BCR presubmit will verify those targets can be built correctly when used as dependencies of a simple anonymous module.

For example, in `zlib@1.2.13`'s [presubmit.yml](https://github.com/bazelbuild/bazel-central-registry/blob/main/modules/zlib/1.2.13/presubmit.yml#L13):

```yaml
matrix:
  platform:
  - centos7
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

**Note that** the task config syntax follows [Bazel CI's specifications](https://github.com/bazelbuild/continuous-integration/tree/master/buildkite#configuring-a-pipeline).

### Test module

It's **highly recommended** to specify a test module that includes example usages of your module, which will help verify the basic APIs and functionalities of your module work correctly.

A test module is located in a subdirectory of the extracted and patched source tree of the target module (the module you want to check in). You can specify the tasks in the `presubmit.yml` file under `bcr_test_module`. A `MODULE.bazel` file should be in the test module directory, and it can depend on the target module with `local_path_override`. With the test module, you can introduce additional dependencies for testing without affecting the target module.

For example, in `rules_jvm_external@4.4.1`'s [presubmit.yml](https://github.com/bazelbuild/bazel-central-registry/blob/main/modules/rules_jvm_external/4.4.2/presubmit.yml) file:

```yaml
bcr_test_module:
  module_path: examples/bzlmod
  matrix:
    platform:
    - centos7
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

**Note that** the task config syntax also follows [Bazel CI's specifications](https://github.com/bazelbuild/continuous-integration/tree/master/buildkite#configuring-a-pipeline), but just one level deeper under `bcr_test_module` and you have to specify the subdirectory of the test module via `module_path`.

## Yank a module version

If a module version is discovered with security vulnerabilities or for any reason should no longer be used, you can yank the module version by adding it to the `yanked` map in `metadata.json` and provide a reason.

For example, in `zlib`'s [metadata.json](https://github.com/bazelbuild/bazel-central-registry/blob/b842554be071a180d78c3a936c8ee0c94c74e8bd/modules/zlib/metadata.json#L17):

```json
"yanked_versions": {
    "1.2.11": "CVE-2018-25032 (https://github.com/advisories/GHSA-jc36-42cf-vqwj)",
    "1.2.12": "CVE-2022-37434 (https://github.com/advisories/GHSA-cfmr-vrgj-vqwv)"
}
```

A Bzlmod user's build will start to fail if the yanked version is in the resolved dependency graph, and the yanked reason will be presented in the error message. The user can choose to upgrade the dependency or they can bypass the check by specifying the `--allow_yanked_versions` flag or the `BZLMOD_ALLOW_YANKED_VERSIONS` environment variable. Check [the documentation](https://bazel.build/reference/command-line-reference#flag--allow_yanked_versions) to learn how to use them.

## Versions format

Bazel has a diverse ecosystem and projects using various versioning schemes, check [Bzlmod's version specification](https://bazel.build/external/module#version_format). If you need to update a module with only patch file changes, you can add `.bcr.<N>` suffix to the version number.

## Requesting to take down a module

If for any reason, you think a module or a version of a module should be removed from the Bazel Central Registry, please [file a bug](https://github.com/bazelbuild/bazel-central-registry/issues/new?assignees=&labels=bug&template=bug.yaml&title=%5BBug%5D%3A+) and reach out to BCR maintainers at bcr-maintainers@bazel.build.
