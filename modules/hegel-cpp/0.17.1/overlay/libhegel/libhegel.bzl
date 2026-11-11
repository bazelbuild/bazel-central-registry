# Downloads the prebuilt libhegel shared library for each released platform.
#
# Keep the version equal to the one in libhegel/Cargo.toml of this tree: that
# is the engine the frontend was released against, and the release's hegel.h
# is the include/hegel.h that //libhegel compiles against. darwin/amd64 is
# intentionally absent: no prebuilt libhegel is published for it.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

LIBHEGEL_VERSION = "0.51.1"

# Platform -> (file extension, SHA-256 of the released asset, as published in
# its .sha256 sidecar).
_ASSETS = {
    "darwin-arm64": ("dylib", "4f443742351498e28939b150e6091804fa1c561253819612c9a412a22e8f0a56"),
    "linux-amd64": ("so", "f0d6243d5ea755c17cc81289918e5cb604902ec1b7c695087f673e6287b11d39"),
    "linux-arm64": ("so", "131df241cb5b4262a56fca4c4fa5584c95d83c5f9dd8b657e4549712a7fbfac2"),
}

def _libhegel_impl(_module_ctx):
    for platform, info in _ASSETS.items():
        ext = info[0]
        sha256 = info[1]
        http_file(
            name = "libhegel-" + platform,
            # The on-disk name matches the Rust output stem (libhegel_c.<ext>)
            # so the Linux SONAME and the macOS @rpath name both resolve to
            # this file.
            downloaded_file_path = "libhegel_c." + ext,
            sha256 = sha256,
            # The monorepo tags a libhegel release `libhegel/<version>`.
            url = "https://github.com/hegeldev/hegel/releases/download/libhegel/{version}/libhegel-{platform}.{ext}".format(
                version = LIBHEGEL_VERSION,
                platform = platform,
                ext = ext,
            ),
        )

libhegel = module_extension(implementation = _libhegel_impl)
