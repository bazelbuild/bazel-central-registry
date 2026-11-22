# openssl

openssl has its own complex build system which performs platform-specific code and config generation.

It is also a security-critical library.

Bazel support for openssl is maintained in https://github.com/raccoons-build/bazel-openssl-cc and publishes to the bazel-central-registry from there.

Because of the combination of complex builds and its security sensitivity, the openssl module doesn't accept pull requests directly to this repository.

To make a contribution to the openssl module, make a pull request to https://github.com/raccoons-build/bazel-openssl-cc where it will run through CI and be reviewed. There is an automated CI workflow in the bazel-openssl-cc repo which will create a release PR in the bazel-central-registry.

This module should only ever receive new versions from the GitHub user [@raccoons-build-bot](https://github.com/raccoons-build-bot). Any pull requests from other users should be closed with a direction to follow the instructions in this README.
