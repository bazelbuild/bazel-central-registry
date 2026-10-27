# Bazel Central Registry

## Overview

The Bazel Central Registry (BCR) is the default registry for Bazel's external dependency system ("Bzlmod"). This is the GitHub repository backing the contents of the BCR, hosted at https://bcr.bazel.build/. For the website that allows you to search modules and see their versions conveniently, visit https://registry.bazel.build/.

Besides hosting metadata about Bazel-specific libraries (commonly known as "rulesets"), the BCR is also a central host for projects that don't have upstream support for Bazel (most commonly, C/C++ projects).

The BCR is just like a regular [Bazel registry](https://bazel.build/external/registry), with some extra metadata fields and policy restrictions. You can contribute to the BCR by sending pull requests; see [BCR policies](docs/bcr-policies.md) and [contribution guidelines](docs/README.md) for more information.

## WheelOS validation and publication

Run these commands from this registry checkout, inside the managed development
container as the mapped non-root user:

```sh
bazelisk test //tools:check_registry_changes_test //tools:publish_registry_test //tools:wheelos_presubmit_test
bazelisk run //tools:check_registry_changes -- --base <previous-registry-commit>
bazelisk run //tools:wheelos_presubmit -- --module=<name>@<version> --bazel-version=8.8.1 --base=<previous-registry-commit>
```

Published version directories are append-only. Correct a broken version by
adding a revision and yanking the old version in metadata; do not rewrite its
source, patches, or hashes. New entries require checksummed HTTPS archives.
Uploaded release assets are preferred but not required. The WheelOS presubmit
accepts HTTPS GitHub archives pinned to a full 40-character commit or a numeric
release tag (`refs/tags/1.2.3` or `refs/tags/v1.2.3`), waiving only upstream's
optional URL byte-stability classification. Branches, short hashes and floating
tags receive no waiver. Tag archives are accepted by project policy, not
classified as intrinsically immutable: never move release tags, and changed
archive bytes must fail integrity verification. Source-repository matching,
download integrity, overlays/patches and MODULE consistency remain mandatory;
changed archive bytes must fail rather than updating an existing integrity.

Pull requests validate changed metadata and every new entry's declared Ubuntu
22.04 Bazel matrix. Consumers fetch from this registry without local source
overrides. The spconv generation presubmit is not GPU execution evidence;
its CUDA 12.8 / SM89 consumer needs a separate GPU build and runtime test.

Production publication requires the validation workflow to succeed and the
`registry-production` GitHub environment to be configured with the existing R2
credentials and appropriate deployment protection. Only registry content is
uploaded, immutable objects use conditional creation, and metadata is written
last with concurrency checks. Nothing is deleted. A new upload or newly
advertised version not validated in that run blocks publication; after an
earlier failed deployment, use the manual workflow's earlier `base` to include
all outstanding versions in validation.

## Upstream infrastructure disclaimer

The core infrastructure of the Bazel Central Registry depends on GitHub and Google Cloud. Bazel users who enable Bzlmod (the default since Bazel 8) depend on the BCR by default. While we try to keep the BCR infrastructure simple and reliable, we assume no liability for any damages caused by build failures due to potential BCR infrastructure failures.

If you consider it necessary, you can do the following to avoid depending on the BCR infrastructure while still making use of the information checked into the BCR.

- Clone the BCR repository or mirror the content to your own infrastructure and use the [--registry](https://bazel.build/reference/command-line-reference#flag--registry) option to change the default Bazel registry to your own.
  - `--registry` is a flag that can be specified multiple times.
  - If no `--registry` flag is specified, the BCR is the only registry Bazel consults.
  - If _any_ `--registry` flag is specified, Bazel will consult the specified registries in order, but will not consult the BCR unless the BCR is explicitly specified as a registry. In other words, to use your own registry layered on top of the BCR, use `--registry=https://my.own.registry.com/ --registry=https://bcr.bazel.build/`.
- Host your own mirror for all source archive URLs and add the mirror URL in `./bazel_registry.json`.
  You can run `bazel run //tools:print_all_src_urls` to get the list of source URLs to mirror for all Bazel modules checked into the BCR.
  For example, `https://foo.com/bar.zip` should be mirrored to `https://<your mirror>/foo.com/bar.zip`.
