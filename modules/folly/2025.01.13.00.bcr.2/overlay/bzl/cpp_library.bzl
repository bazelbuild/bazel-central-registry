"""Wrapper around cc_library for folly."""

load("@rules_cc//cc:defs.bzl", "cc_library")

def cpp_library(name, **kwargs):
    deps = kwargs.pop("deps", [])

    # Append as a list like this so it still works if deps contains a select statement.
    # buildifier: disable=list-append
    deps += ["//:include_hack"]

    cc_library(
        name = name,
        deps = deps,
        **kwargs
    )
