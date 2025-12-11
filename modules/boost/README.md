# Boost Meta-Module

The `boost` module is a meta-module that is not meant to be directly added as a bazel_dep.

Its purpose is to ensure that all boost sub-modules included in a workspace are the same version.

## Adding a New Boost Version

```bash
python3 modules/boost/add_boost_version.py <version>
```

This script will create a new version of all the boost submodules.

Whenever a new version of a boost sub-module is created, it is expected that a corresponding version will be created for all of them, including this boost meta-module.

For example, let's say you are updating the boost module `boost.algorithm` by creating a new bcr version `1.89.0.bcr.3`. You would first run the add_boost_version.py script to create `1.89.0.bcr.3` for all boost submodules. Then apply your changes to `boost.algorithm` as needed.
