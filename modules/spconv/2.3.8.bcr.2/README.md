# spconv 2.3.8.bcr.2

This is the official pinned spconv source archive plus a Bazel integration
patch and a checksummed generated-source supplement. The supplement is
registry-maintained, not an upstream release or precompiled library.

## Contents

- `source.json`: immutable upstream URL, source integrity, patch and overlay
  integrity. The official source digest is unchanged from `.bcr.1`.
- `patches/bazel-integration.patch`: module, BUILD targets, source extraction
  rule and consumer documentation (`README.bazel.md` in the extracted source).
- `overlay/bazel/generated-inference-sm89.tar.xz`: 20,881 source/header,
  documentation, license and manifest files; approximately 1.2 MB compressed.
- `package_sources.py`: deterministic repackaging of the existing pinned
  generated tree. It neither downloads sources nor runs code generation.

Unneeded generated CMake definitions containing absolute preparation paths are
omitted. C++/CUDA source and header bytes are preserved. The source manifest
records CUDA 12.8 / SM89 and pinned spconv/cumm/code-generator versions.
Generation reproducibility is not claimed from manifest inspection alone.

## Repackage

From this version directory, using a separately prepared source tree matching
the recorded manifest:

```sh
python3 package_sources.py \
  --source-tree=/path/to/prepared/inference-source \
  --output=/path/to/new/generated-inference-sm89.tar.xz
```

The output must not exist. SHA-256 of this revision's supplement is
`afbe4a1bdff368b95d242f37050e71da333c9cabeef980da211a3b2383929289`.
A packaging check must compare that digest, not just file counts.

Run the focused packaging checks from this directory with:

```sh
python3 -B -m unittest package_sources_test
```

On 2026-10-26, the repackaging tool reproduced the shipped archive byte for
byte. Apollo's `--config=dev` consumer resolved `.bcr.2` from this local registry,
built the BEVFusion, CenterPoint and PointPillars runtime DSOs, and passed
the sparse parser, BEVFusion runtime ABI and backend tests without
`SPCONV_SOURCE_ROOT`. This establishes local packaging/build integration,
not new full-dataset accuracy results or remote registry publication.

The official BCR validator passed required source integrity, patch application,
MODULE parity, metadata and presubmit checks (exit 42: maintainer review
required). Its optional `url_stability` check was explicitly skipped: GitHub's
auto-generated commit archive pins source identity but does not promise
byte-stable archive regeneration. Source integrity remains enforced; disclose
this waiver in any registry submission. No maintainer approval is claimed.

## Validation boundaries

Registry consumers no longer need `SPCONV_SOURCE_ROOT`, Python generator
packages or local source preparation. They still require a compatible CUDA
toolchain for `@spconv//:spconv`. The source-only presubmit checks do not prove
GPU inference; build consumers and run model/executor tests separately.
This supplement covers CUDA 12.8 / SM89, not Orin/SM87 or every upstream
configuration. Do not rewrite this revision for another architecture.

Local registry consumption is not registry publication. No release upload,
commit or push is implied by adding these files.
