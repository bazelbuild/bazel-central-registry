"""The Apache Thrift version bundled by Arrow's upstream CMake build."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _apache_arrow_deps_impl(_module_ctx):
    http_archive(
        name = "apache_arrow_thrift",
        build_file = Label("//:thrift.BUILD.bazel"),
        sha256 = "c4649c5879dd56c88f1e7a1c03e0fbfcc3b2a2872fb81616bffba5aa8a225a37",
        strip_prefix = "thrift-0.22.0",
        urls = ["https://github.com/apache/thrift/archive/refs/tags/v0.22.0.tar.gz"],
    )

apache_arrow_deps = module_extension(
    implementation = _apache_arrow_deps_impl,
)
