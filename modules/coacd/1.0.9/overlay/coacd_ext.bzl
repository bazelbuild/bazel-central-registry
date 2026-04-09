load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _cdt_ext_impl(ctx):
    http_archive(
        name = "cdt",
        build_file_content = """
load("@rules_cc//cc:defs.bzl", "cc_library")
cc_library(
    name = "cdt",
    hdrs = glob(["CDT/include/**/*.h", "CDT/include/**/*.hpp", "CDT/include/**/*.inl"], allow_empty = True),
    includes = ["CDT"],
    visibility = ["//visibility:public"],
)
""",
        strip_prefix = "CDT-1.4.1",
        urls = ["https://github.com/artem-ogre/CDT/archive/refs/tags/1.4.1.tar.gz"],
    )

cdt_ext = module_extension(implementation = _cdt_ext_impl)