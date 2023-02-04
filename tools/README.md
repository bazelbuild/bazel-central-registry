# BCR Helper Scripts

## add_module.py

An interactive script for adding a module to the BCR.
```
$ bazel run //tools:add_module
INFO: Getting module information from user input...
ACTION: Please enter the module name:
...
```

## calc_integrity.py

Calculate integrity value of a local file or a file downloaded at a URL.
```
$ ./tools/calc_integrity.py https://github.com/madler/zlib/archive/refs/tags/v1.2.13.zip
sha256-woVpUbvzDjCGGs43ZVldhroT8s8BJ52QH2xiJYxX9P8=

$ ./tools/calc_integrity.py ./v1.2.13.zip
sha256-woVpUbvzDjCGGs43ZVldhroT8s8BJ52QH2xiJYxX9P8=
```

## bcr_validation.py

A script to validate module information in the BCR. It is used in the BCR presubmit.
```
usage: bcr_validation.py [-h] [--registry REGISTRY] [--check CHECK] [--check_all] [--check_all_metadata] [--fix]

optional arguments:
  -h, --help            show this help message and exit
  --registry REGISTRY   Specify the root path of the registry (default: the current working directory).
  --check CHECK         Specify a Bazel module version you want to perform the BCR check on. (e.g. bazel_skylib@1.3.0). If no version is specified, all versions of that module are
                        checked. This flag can be repeated to accept multiple module versions.
  --check_all           Check all Bazel modules in the registry, ignore other --check flags.
  --check_all_metadata  Check all Bazel module metadata in the registry.
  --fix                 Should the script try to fix the detected validation errors.
```

## print_all_src_urls.py

Print the list of source archive URLs of all modules in the BCR.
```
$ bazel run //tools:print_all_src_urls
https://github.com/bazelbuild/rules_jvm_external/archive/refs/tags/4.4.2.zip
https://github.com/bazelbuild/rules_jvm_external/archive/refs/tags/4.5.zip
...
```

## migrate_to_bzlmod.py

A helper script for migrating your external dependencies from WORKSPACE to Bzlmod. For given targets, it first tries to generate a list of external dependencies for building your targets,
then tries to detect and add missing dependencies in the Bzlmod build. You may still need to fix some problems manually.

```
usage: migrate_to_bzlmod [-h] [-s] [-f] [-i] [-t TARGET]

options:
  -h, --help            show this help message and exit
  -s, --sync            use `bazel sync` instead of `bazel build --nobuild` to generate the resolved dependencies. `bazel build --nobuild` only fetches dependencies needed for building
                        specified targets, while `bazel sync` resolves and fetches all dependencies defined in your WORKSPACE file, including bind statements and execution platform &
                        toolchain registrations.
  -f, --force           ignore previously generated resolved dependencies.
  -i, --interactive     ask the user interactively on what to do.
  -t TARGET, --target TARGET
                        specify the targets you want to migrate. This flag is repeatable, and the targets are accumulated.

Example usage: change into your project directory and run `<path to BCR repo>/tools/migrate_to_bzlmod.py --target //foo:bar`
```
