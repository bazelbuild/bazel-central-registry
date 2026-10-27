# spconv inference generation under Bazel

This revision uses official spconv 2.3.8 source at
`263d6b47425ef843c82f997b12d8b714013d216c`. Upstream `spconv.gencode` runs
in an execution-phase Bazel action, not during repository resolution. Bazel
declares each generated header, C++ and CUDA file explicitly, then compiles
with the existing `cc_library` and `cuda_library` rules. There is no generated
source supplement, environment source directory, JIT compilation, or pip
installation inside a build action.

## Fixed scope and build tools

Generation is inference-only, namespace `spconvlib`, CUDA 12.8, SM89.
The action requires a Linux x86_64 execution platform and managed Python 3.10.
Python dependencies are version/hash-locked in `bazel/requirements_lock.txt`.
The separately checksummed official cumm 0.7.11 CPython 3.10 Linux wheel
supplies generator descriptions, tensorview headers and the native helper
imported by upstream generation. Its headers match the prior source
supplement byte-for-byte; the regenerated 20,772 C++/CUDA/header files match
the prior working output byte-for-byte. The wheel is a build tool, not a
precompiled spconv runtime. Consumers do not link Python or that native helper.

`bazel/cumm-codegen.patch` removes CUDA compiler detection and supplies empty
CUDA include/library metadata in explicit codegen mode. Those paths are only
used by upstream's discarded CMake files; Bazel supplies real compilation
toolchains. Architecture/version inputs remain explicit. The overlay version
module is the file normally produced by upstream's setup script.

Generation checks the exact file set and SHA-256 of every declared output;
missing, unexpected or modified outputs fail the action. Generated CMake files
are discarded because they embed generation paths and are not compilation
inputs. Updating generators/configuration requires intentionally regenerating
and reviewing the output manifest.

## Public targets

- `@spconv//:spconv`: native static inference library.
- `@spconv//:generated`: verified generated sources, usable without a GPU/toolkit.
- `@spconv//:licenses`: upstream spconv and cumm Apache-2.0 notices.
- `@spconv//:source_manifest`: `spconv-source.json` provenance, including
  integration input digests (output inventory, Python lock and adapter).

License basenames remain `SPCONV-LICENSE` and `CUMM-LICENSE`. The source
manifest remains one JSON file, preserving the previous public target shape.

For native compilation, the consumer must configure CUDA 12.8 and directly
declare `rules_cuda` when using its command-line settings:

```sh
bazel build --compilation_mode=opt --cxxopt=-std=c++17 \
  --@rules_cuda//cuda:enable=true --@rules_cuda//cuda:archs=sm_89 \
  @spconv//:spconv
```

Building a static host archive alone does not force all dependent CUDA
archives to compile or link. Consumer acceptance must build/link an executable
and run the sparse-graph numerical/stream regression on SM89 hardware.
No SM87/Orin, other CUDA version, training, or full-dataset accuracy acceptance
is implied. Old registry revisions remain unchanged.
