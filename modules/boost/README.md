# Boost Meta-Module

The `boost` module is a meta-module that is not meant to be directly added as a bazel_dep.

Its purpose is to ensure that all boost sub-modules included in a workspace are the same version.

## Adding a New Boost Version

```bash
python3 modules/boost/add_boost_version.py <version>
```

This script will create a new version of all the boost submodules.

It is only necessary to run this when creating a new version of boost, e.g. 1.89 -> 1.90. You do not need to run this script when just creatinga a new bcr version for a boost module.
