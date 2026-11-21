"""Pinned GLib and PCRE2 release archives with hermetic build adaptations."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

_BCR = "https://bcr.bazel.build/modules/glib/2.84.4.bcr.1/overlay/"
_FILES = {
    "BUILD.bazel": "sha256-Fl4mzdkqcA+qX1kcSWrMXSsOA4g3DP1R2/1tG91mtK0=",
    "config.h-linux": "sha256-Zm2bhKLp/RqdEz0nprG8dbJVWW4ROy4fh8I07zwkiKY=",
    "config.h-macos": "sha256-bt6MvmC7GqzwidoQUtb1zxO3E/9Q+YSBloSO9AQUObM=",
    "config.h-windows": "sha256-prCz7bCOX6749eOdXMBJwASEJYLDGUlZqNdkz5JaLNo=",
    "glib/BUILD.bazel": "sha256-Gz1vaBsceetsS/pScJ4Kitl2bKb1TriVbDXfsGEa570=",
    "glib/glibconfig.h.in-posix": "sha256-7p3GwTRBI8JYr4sitZcW1WYxu5iHGzbJtmfQq5o2++M=",
    "glib/glibconfig.h.in-windows": "sha256-XRjv+oXxLTwPZMWhc5VbgiV0ClPJuZdfVZcpTkzNNJI=",
    "glib/gnulib/BUILD.bazel": "sha256-64IUga81i/VlhOTGV1y16J3BewqmzQntwairXXEyuLA=",
    "glib/gnulib/gnulib_math.bzl": "sha256-kcvr6q47RTti4n0SidcS/pNCiUglgk7BewJOoYpyZrQ=",
    "glib/stub_libintl/libintl.h": "sha256-PM2cAOL/zslqWpFdHUDyhWGIfCaplAanHYJ3Zuj8HB8=",
    "gmodule/BUILD.bazel": "sha256-SLlENI6Esz32X6SgJbEul7dO6R7j/RgTfuJp8/gswrQ=",
    "tools/BUILD.bazel": "sha256-ChwrZQCubLfMjhboGAhjp/erj0CUSiBNbt8hypaN1sc=",
}

def _impl(mctx):
    http_archive(
        name = "qemu_pcre2",
        urls = ["https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.49/pcre2-10.49.tar.bz2"],
        integrity = "sha256-U8FW4bpBaiDajmU5XaoTLaDYDnaRBCTKyj/Nrngx04Q=",
        strip_prefix = "pcre2-10.49",
        patches = [Label("//bazel/deps:pcre2_copy.diff")],
        patch_args = ["-p1"],
    )
    http_archive(
        name = "qemu_glib",
        urls = ["https://download.gnome.org/sources/glib/2.84/glib-2.84.4.tar.xz"],
        integrity = "sha256-ip6hCUPDb8EX4lP4DJHkd7ZzUlrkV2KUKFiu9XYxu5A=",
        strip_prefix = "glib-2.84.4",
        remote_file_urls = {path: [_BCR + path] for path in _FILES},
        remote_file_integrity = _FILES,
        patches = [Label("//bazel/deps:glib_musl.diff")],
        patch_args = ["-p1"],
    )
    return mctx.extension_metadata(reproducible = True)

static_deps = module_extension(implementation = _impl)
