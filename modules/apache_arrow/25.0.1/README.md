# Apache Arrow C++

The BUILD overlay follows the source lists and generated configuration in
Apache Arrow's CMake build. It exposes the Arrow, Acero, Parquet, and Dataset
libraries, with CSV, JSON, IPC, local filesystems, and common compression codecs
enabled. The module uses the system allocator rather than bundling jemalloc or
mimalloc.

Apache Thrift is not available as a Bazel Central Registry module, so the module
extension downloads the exact Thrift 0.22.0 release selected by Arrow 25.0.1
and builds only the compact-protocol sources needed by Parquet.

Azure Storage support can be enabled with:

```text
--@apache_arrow//:with_azure --@curl//:ssl_lib=openssl
```

Amazon S3 support is available on Linux and can be enabled with:

```text
--@apache_arrow//:with_s3 --@curl//:ssl_lib=openssl
```

The OpenSSL flag allows the Azure and AWS SDKs to share one TLS implementation.
