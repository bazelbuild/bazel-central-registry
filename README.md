# Bazel Central Registry

**Status:** This repository is in beta test phase, feel free to submit your project as Bazel module. During the test phase, checked in modules may still change without any notice.

## Overview

The default Bazel registry for the Bzlmod external dependency system of Bazel. It is the recommended place to find and publish your favorite Bazel projects. Visit https://registry.bazel.build to check what modules are already available!

## Contributing

To contribute, check our [BCR  policies](docs/bcr-policies.md) and [contribution guidelines](docs/README.md).

## Depending on the BCR infrastructure (and how not to)

The core infrastructure of the Bazel Central Registry depends on Github and Google Cloud. Bazel users who enable Bzlmod by default depend on the BCR.
While we try to keep the BCR infrastructure simple and reliable, we're not responsible for any damages caused by build failures due to potential BCR infrastructure failures.

If you consider it's necessary, you can do the following to avoid depending on the BCR infrastructure while still making use of the information checked in the BCR.

- Clone the BCR repository or mirror the content to your own infrastructure and use `--registry` option to change the default Bazel registry to your own.
- Host your own mirror for all source archive URLs and change the mirror URL in `./bazel_registry.json` to your own.
  You can run the `./tools/print_all_src_urls.py` script to get the list of source URLs for all Bazel modules checked in the BCR.
  For example, `https://foo/bar.zip` should be mirrored to `https://<your mirror>/foo/bar.zip`.
