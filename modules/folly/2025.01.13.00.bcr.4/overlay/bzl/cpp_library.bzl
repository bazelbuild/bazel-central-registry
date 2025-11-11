"""Wrapper around cc_library for folly."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

def cpp_library(name, **kwargs):
    deps = kwargs.pop("deps", [])

    cc_library(
        name = name,
        deps = deps + [Label("//:include_hack")],
        **kwargs
    )
