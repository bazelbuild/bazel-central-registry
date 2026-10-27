# spconv Bazel integration

This module retrieves spconv 2.3.8 at commit
`263d6b47425ef843c82f997b12d8b714013d216c` from its immutable upstream
archive. The registry supplies only Bazel integration overlays, not a
precompiled library or a generated-source release.

Upstream's C++ API requires a separate Python code-generation stage; its
archive is not directly buildable as the generated C++ library. This module
owns that stage's script, version pins, generated-source repository and BUILD
definitions. No Apollo-specific code is included.

## Prepare sources

Use a non-root user with CUDA and an isolated Python environment containing
spconv 2.3.8 and cumm 0.7.11 (including cumm's compiled bindings), following
upstream `docs/PURE_CPP_BUILD.md`. The validated Python 3.10 generator uses
pccm 0.4.16, ccimport 0.4.4, NumPy 2.2.6 and SymPy 1.14.0.
Set `PYTHONPATH` to that environment if using `pip --target` installations.
Do not install or import PyTorch just to build the runtime.

With checkouts at the revisions in `bazel/versions.json`:

```sh
bazel run @spconv//:prepare_source -- \
  --spconv="$SPCONV_CHECKOUT" --cumm="$CUMM_CHECKOUT" \
  --output="$GENERATED_SOURCE_ROOT" --cuda-arch=8.9 --cuda-version=12.8
```

Use a Python toolchain compatible with the codegen environment's compiled
cumm bindings (3.10 in the validated consumer). Preparation refuses to
overwrite an existing directory. It copies the upstream licenses and writes
`spconv-source.json`. Imported package versions and checkout commits are
checked; consumers must ensure the imported packages actually came from those
checkouts. Metadata does not authenticate a mutable generated tree.

```sh
bazel build --repo_env=SPCONV_SOURCE_ROOT="$GENERATED_SOURCE_ROOT" \
  --@rules_cuda//cuda:enable=true --@rules_cuda//cuda:archs=sm_89 \
  @spconv//:spconv
```

The codegen architecture must match the selected CUDA target. `@spconv`
exposes the source-built inference library, and `@spconv//:licenses` exposes
the spconv and cumm Apache-2.0 licenses for packaging.
No Python dependencies are needed at runtime.

## Build boundaries

CUDA headers and libraries come from `rules_cuda`'s toolkit repository.
The consumer configures/discovers its CUDA installation. Generated host
objects are retained because CUDA objects call back into them; the library
is static so downstream shared consumers do not need another spconv DSO.
Only generated host code downgrades initialization-order warnings from errors.

Generic registry CI builds upstream sources and the preparation CLI only.
CUDA compilation requires a prepared tree and toolkit; it is validated
separately in the Apollo GPU consumer. Neither registry metadata validation
nor a CLI build alone proves GPU inference or a hermetic source release.

Publishing a checksummed generated-source archive could remove the explicit
preparation dependency in a future module revision. This entry does not
publish such an artifact, download unpinned binaries, invoke pip, or run
codegen implicitly during repository resolution.
