# Bazel Central Registry

## Overview

The Bazel Central Registry (BCR) is the default registry for Bazel's external dependency system ("Bzlmod"). This is the GitHub repository backing the contents of the BCR, hosted at https://bcr.bazel.build/. For the website that allows you to search modules and see their versions conveniently, visit https://registry.bazel.build/.

Besides hosting metadata about Bazel-specific libraries (commonly known as "rulesets"), the BCR is also a central host for projects that don't have upstream support for Bazel (most commonly, C/C++ projects).

The BCR is just like a regular [Bazel registry](https://bazel.build/external/registry), with some extra metadata fields and policy restrictions. You can contribute to the BCR by sending pull requests; see [BCR policies](docs/bcr-policies.md) and [contribution guidelines](docs/README.md) for more information.

## Disclaimer

The core infrastructure of the Bazel Central Registry depends on GitHub and Google Cloud. Bazel users who enable Bzlmod (the default since Bazel 8) depend on the BCR by default. While we try to keep the BCR infrastructure simple and reliable, we assume no liability for any damages caused by build failures due to potential BCR infrastructure failures.

If you consider it necessary, you can do the following to avoid depending on the BCR infrastructure while still making use of the information checked into the BCR.

- Clone the BCR repository or mirror the content to your own infrastructure and use the [--registry](https://bazel.build/reference/command-line-reference#flag--registry) option to change the default Bazel registry to your own.
  - `--registry` is a flag that can be specified multiple times.
  - If no `--registry` flag is specified, the BCR is the only registry Bazel consults.
  - If _any_ `--registry` flag is specified, Bazel will consult the specified registries in order, but will not consult the BCR unless the BCR is explicitly specified as a registry. In other words, to use your own registry layered on top of the BCR, use `--registry=https://my.own.registry.com/ --registry=https://bcr.bazel.build/`.
- Host your own mirror for all source archive URLs and add the mirror URL in `./bazel_registry.json`.
  You can run `bazel run //tools:print_all_src_urls` to get the list of source URLs to mirror for all Bazel modules checked into the BCR.
  For example, `https://foo.com/bar.zip` should be mirrored to `https://<your mirror>/foo.com/bar.zip`.
