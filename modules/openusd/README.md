# OpenUSD

## Overview

This module allows linking a minimal build of OpenUSD as a static monolithic library. OpenUSD supports many optional addons and plugins, including Python support, but
those are disabled here. Please refer to the README and BUILDING.md files of the OpenUSD repo on GitHub if you require a different build.

As explained in the OpenUSD BUILDING.md, there are several different ways to build OpenUSD (static vs shared and monolithic vs split-up). This Bazel module builds it
as a monolithic static library, for ease of use. 

Note: We currently only support building for linux.

## Working with this BCR module

If you must modify or update this BCR module, first read these docs:
https://github.com/bazelbuild/bazel-central-registry/blob/main/docs/README.md
https://bazel.build/external/registry

Commands cheat-sheet:

Run this to create a new BCR version:
bazel run //tools:add_module

Run this to update the integrity checksums in the source.json (for patches and overlay files):
bazel run -- //tools:update_integrity openusd

Run the validations:
bazel run -- //tools:bcr_validation --check=openusd@25.11

### Testing Locally

To test the module locally, run this:

Run:
bazel shutdown && bazel build --enable_bzlmod --registry="file:///usr/local/google/home/mattriley/bazel-central-registry" --lockfile_mode=off //:main
Or just:
bazel test --enable_bzlmod --registry="file:///usr/local/google/home/mattriley/bazel-central-registry" --lockfile_mode=off //:test_main
