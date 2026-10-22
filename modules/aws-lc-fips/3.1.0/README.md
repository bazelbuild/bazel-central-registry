# AWS-LC FIPS 3.1.0 BCR integration

The public C/C++ interface and supported configuration are documented in
`overlay/README.bazel.md`. This module consumes only the shared build rule from
`aws-lc@5.1.0.bcr.4`; it builds the FIPS release's native sources and Go tools.
The crypto and SSL source lists in `overlay/sources.bzl` follow this release's
`crypto/CMakeLists.txt` and `ssl/CMakeLists.txt`. The s2n-bignum lists follow
`crypto/fipsmodule/CMakeLists.txt`. Generated perlasm is shipped in the archive.

Validation performed:

- x86-64 smoke, upstream crypto exercise and integrity tests pass with GCC
  12.5.0 on Bazel 7.6.1, 8.5.0 and 9.2.0. The Bazel 7 and 8 checks also
  exercise the registry archives, overlays and patch without local overrides.
- Crypto, SSL and test executables cross-build for AArch64 with GCC 12.5.0.
- Under QEMU 10.2.1, the AArch64 static binary's startup integrity check passes;
  corrupting its module makes startup fail with `FIPS integrity test failed`.
- Full AArch64 runtime verification remains assigned to native Arm presubmit:
  this host's QEMU/runtime combination returns EDEADLK (35) on an uncontended
  pthread rwlock, reproduced in a standalone executable without AWS-LC. Its
  dynamic loader also faults on a minimal executable without AWS-LC.

BCR's validator accepts the checksums, metadata, MODULE overlay and presubmit
configuration. It requires maintainer review for this new module. AWS attaches
no source archive to the AWS-LC-FIPS-3.1.0 GitHub release; submission needs the
standard `@bazel-io skip_check unstable_url` waiver for the checksummed tag URL.
The module maintainer list follows the existing AWS-LC entry and needs approval
as part of the new-module review.

The single patch changes only the corruption test utility's build tag. The
`ignore` tag would enable unrelated generators throughout Go's standard library;
a dedicated tag permits rules_go to build the explicitly selected test tool.
No cryptographic source is patched.
