"""Wrapper around cc_library for folly."""

load("@rules_cc//cc:defs.bzl", "cc_library")

def cpp_library(name, **kwargs):
    #repo_root = native.package_relative_label(":BUILD.bazel").workspace_root
    #include_prefix = repo_root if repo_root else "."

    #includes = kwargs.pop("includes", [])
    #includes.append(include_prefix)

    #print("name")
    #print(include_prefix)

    deps = kwargs.pop("deps", [])
    # Append as a list to still work if deps contains a select statement.
    # buildifier: disable=list-append
    deps += ["//:include_hack"]

    cc_library(
        name = name,
        deps = deps,
        **kwargs
    )
