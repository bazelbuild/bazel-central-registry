# AWS-LC FIPS 3.1.0: native static build

Depend on `@aws-lc-fips//:crypto` (or `:ssl`) from a C/C++ target.
Linux x86-64 and AArch64 are supported; other target platforms are explicitly
incompatible.
The two modules can coexist: `aws-lc` is used only for its shared Starlark rules,
not its native library.

The FIPS module is built from the checksummed AWS-LC-FIPS-3.1.0 release and
uses that release's generated perlasm sources.
The Go `delocate` and `inject_hash` tools are compiled with rules_go and selected
as execution-platform tools.
Native actions use the resolved C/C++ toolchain; they default to the host
toolchain but a hermetic one can be provided.

This initial integration uses the default OS entropy source, does not enable the
optional CPU-jitter source, and supports static linking only.

Sanitizer, coverage and LTO builds of the module are not supported because they
can change the integrity-protected code after hashing.

Presubmit checks upstream tests for crypto operations, FIPS mode validation, and
rejection of a corrupted module; check them when developing with
`bazel test @aws-lc-fips//:upstream_fips_test @aws-lc-fips//:fips_smoke_test @aws-lc-fips//:integrity_test`.

This adds native-library support only. Rust crates require a separate
`aws-lc-fips-sys` integration that supplies matching symbols, bindings and Cargo
metadata. The default libraries use unprefixed symbols. Adapters can instantiate
`aws_lc_fips_libraries` from `@aws-lc-fips//bazel:defs.bzl`, supplying their symbol
prefix and matching C/assembly prefix headers. This builds `<name>_crypto`,
`<name>_ssl`, and `<name>_headers`. Prefixing occurs after delocation and before
hash injection; the caller supplies the namespace rather than the module
hardcoding a Rust crate version.
