# Slang

This is a bazel wrapper to build [slang](https://sv-lang.com/).

It includes:

- Slang C++ Libraries
- Binary for the main slang driver
- Binaries for the slang tools (slang-tidy, rewriter, ...)
- Locally-built Python bindings (pyslang)


Pyslang is available on PyPI, but the option of using a local build is provided
to take advantage of the reproducable hermetic build, and to align the versions
used for Slang and Pyslang in a given repository.
