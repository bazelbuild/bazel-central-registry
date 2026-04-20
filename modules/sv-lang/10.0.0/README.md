# Slang (sv-lang)

This is a bazel wrapper to build [slang](https://sv-lang.com/).

It includes:

- Slang C++ Libraries
- Binary for the main slang driver
- Binaries for the slang tools (slang-tidy, rewriter, ...)
- Locally-built Python bindings (pyslang)

## Pyslang

Pyslang is available on PyPI, but the option of using a local build is provided
to take advantage of the reproducable hermetic build, and to align the versions
used for Slang and Pyslang in a given repository.

Because we include the Python bindings, we do not use `mimalloc` in the main slang library build as they are incompatible.


## TODO

Desirable future changes to this build include:

- support multithreading in the C++ with `SLANG_USE_THREADS`
- add `.pyi` stubs for the Pythonbindings
- add a method to patch in CPPTRACE with `SLANG_USE_CPPTRACE`
