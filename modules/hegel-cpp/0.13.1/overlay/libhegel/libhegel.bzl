# Downloads the prebuilt libhegel shared library for each released platform.
#
# Keep the version and the SHA-256 hashes in sync with cmake/libhegel.cmake,
# libhegel/hegel.h, and nix/flake.nix. darwin/amd64 is intentionally absent:
# no prebuilt libhegel is published for it.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

LIBHEGEL_VERSION = "0.42.4"

# Platform -> (file extension, SHA-256 of the released asset).
_ASSETS = {
    "darwin-arm64": ("dylib", "560b6f2b5e724fa6c7300ee52c6c37a2a7ce94cd2d225d6a3ae7ca0adc0e23e8"),
    "linux-amd64": ("so", "60fa1b48f83def125d0d6904bf4351c0022572b52be252ded756aab9e0990682"),
    "linux-arm64": ("so", "b3a8f8041dff28c3657329bb6ecc01d506b1333f76e349efedf18ab555cf4042"),
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
            # hegel-rust tags a libhegel release `libhegel-v<version>`; its
            # plain `v<version>` tags belong to a different crate.
            url = "https://github.com/hegeldev/hegel-rust/releases/download/libhegel-v{version}/libhegel-{platform}.{ext}".format(
                version = LIBHEGEL_VERSION,
                platform = platform,
                ext = ext,
            ),
        )

libhegel = module_extension(implementation = _libhegel_impl)
