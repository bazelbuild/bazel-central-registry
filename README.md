# Bazel Central Registry

**Status:** This repository is in beta test phase, feel free to submit your project as Bazel module. During the test phase, checked in modules may still change without any notice.

## Goal
A registry of Bazel modules for the Bzlmod external dependency system. It is the recommended Bazel registry to publish your Bazel open source projects for downstream users.

For more information, see the [Bazel Central Registry Policies and Procedures](https://docs.google.com/document/d/1ReuBBp4EHnsuvcpfXM6ITDmP2lrOu8DGlePMUKvDnXM/edit?usp=sharing).

## Roles

### Module Contributor

A person who contributes a Bazel module entry to this registry is a module contributor.

To contribute a Bazel module, you can start with the interactive helper script:
```
python3 ./tools/add_module.py
```

### Module Maintainer

A person who maintains a specific module entry in this registry is a module maintainer. The name and contact information of the module maintainers are recorded in the metadata.json file for each module.

**Note that**, a module maintainer doesn't have to be the project owner. Ideally, we prefer the project owner to maintain the module entry, as they know the project the best. But if the project owner is not maintaining the entry, a Bazel user who is interested in making the project available in this registry could also take on the responsibility.

Being a module maintainer means:

  - You will be asked to review future changes of this module entry. For example, a PR for adding a new version for this module.
  - You will be asked for help when a new version of the module is required by users.
  - You should maintain [the compatibility](https://docs.google.com/document/d/1ReuBBp4EHnsuvcpfXM6ITDmP2lrOu8DGlePMUKvDnXM/edit#heading=h.d7dl8s7vxf63) for this module when necessary.

To become a module maintainer, send a PR to add yourself as a maintainer in the metadata.json file of the module you want to maintain.

### Registry Maintainer

Currently, the Bazel team is the registry maintainer, who are responsible for:

  - Review and merge PRs for this repository.
  - Maintain testing and serving infrastructures for the Bazel Central Registry.

## presubmit.yml

We require every module version to have a `presubmit.yml` file for configuring the presubmit tests to verify the integrity of the module.

In the `presubmit.yml` file:

  - You should specify the list of build targets that you want to expose to downstream users.
  - It's highly recommended to have a [test module](https://github.com/bazelbuild/continuous-integration/issues/1302) in your source archive.
  - In general, you should NOT specify unit tests or test suites focusing on implementation details in this file.

The presubmit.yml file will be used for:

  - [Presubmit test](https://docs.google.com/document/d/1ReuBBp4EHnsuvcpfXM6ITDmP2lrOu8DGlePMUKvDnXM/edit#heading=h.1o9h5yrz477i) when checking in the module version
  - [Downstream test](https://docs.google.com/document/d/1ReuBBp4EHnsuvcpfXM6ITDmP2lrOu8DGlePMUKvDnXM/edit#heading=h.c7d1a4rk6dvj) for dependencies of this module
  - [Bazel compatiblity test](https://docs.google.com/document/d/1ReuBBp4EHnsuvcpfXM6ITDmP2lrOu8DGlePMUKvDnXM/edit#heading=h.vp6y2sd6hujz)
