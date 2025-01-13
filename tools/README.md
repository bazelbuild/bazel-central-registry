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

## module_selector.py

This script provides a way to select specific versions of Bazel modules from the Bazel Central Registry (BCR). It supports wildcard patterns for flexible module and version matching, as well as the option to randomly sample a percentage of the matching modules.

```
usage: module_selector.py [-h] [--registry REGISTRY] --select SELECT [--random-percentage PERCENTAGE]

Select module versions matching given patterns.

optional arguments:
  -h, --help            show this help message and exit
  --registry REGISTRY   Specify the root path of the registry (default: the current working directory or the workspace
                        root if running with Bazel).
  --select SELECT       Specify module selection patterns in the format <module_pattern>@<version_pattern>. The
                        <module_pattern> can include wildcards (*) to match multiple modules. The <version_pattern>
                        can be: - A specific version (e.g., "1.2.3") - "latest" to select the latest version - A
                        comparison operator followed by a version (e.g., ">=1.0.0", "<2.0.0") You can provide multiple
                        --select options to select multiple modules. Examples: --select "zlib@latest" --select
                        "protobuf@>=27" --select "rules_*@<1.5.0" --select "*@latest"
  --random-percentage PERCENTAGE
                        Percentage of modules to randomly select from the modules matching any of the patterns. Must
                        be an integer between 1 and 100.
```

You can also run with Bazel, for example:

```bash
bazel run //tools:module_selector -- --select "rules_*@latest"
```

## module_analyzer.py

This script calculates the importance of each module in the BCR based on their PageRank value and prints out the top N important modules.

The graph is constructed based on dependencies of the latest version of each module.

```
usage: module_analyzer.py [-h] [--registry REGISTRY] [--top_n TOP_N] [--exclude-dev-deps] [--name-only]

Select module versions matching given patterns.

optional arguments:
  -h, --help           show this help message and exit
  --registry REGISTRY  Specify the root path of the registry (default: the current working directory or the workspace root if running with Bazel).
  --top_n TOP_N        Specify the top N important modules to print out (default: 50).
  --exclude-dev-deps   Exclude dev dependencies when constructing the dependency graph (default: False).
  --name-only          Only print the module names without the scores (default: False).
```

You can also run with Bazel, for example:

```bash
bazel run //tools:module_analyzer -- --top_n 10
```

## setup_presubmit_repos.py

This script sets up the repos for reproducing BCR presubmit builds locally.
It chooses the first task config that matches the current platform and print out the commands to run.

```
usage: bazel run //tools:setup_presubmit_repos -- --module foo@1.2.0

Setup repos for reproducing BCR presubmit builds locally.

options:
  -h, --help       show this help message and exit
  --module MODULE  Module name and version, e.g. foo@1.2.0
```
