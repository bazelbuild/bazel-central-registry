# Boost Meta-Module

The `boost` module is a meta-module that provides convenient access to all Boost libraries in the Bazel Central Registry.

## Adding a New Boost Version

```bash
python3 modules/boost/add_boost_version.py <version>
```

## Module structure

For all available modules in the given version, an alias will be generated in a subdirectory matching the library name. E.g. `@boost.filesystem` -> `@boost//filesystem`.
