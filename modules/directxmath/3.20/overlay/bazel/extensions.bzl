"""Module extension for fetching the DirectXMath test suite."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

_COMMIT = "8098c31a0c2932eaf0419af3331e46f568243d6e"

def _dxmath_test_impl(_ctx):
    http_archive(
        name = "directxmathtest",
        url = "https://github.com/walbourn/directxmathtest/archive/{}.tar.gz".format(_COMMIT),
        integrity = "sha256-O5AXs0DmuBcaz/rMQkk/ym6z4NQrtfmu6w0z43xNKvs=",
        strip_prefix = "directxmathtest-{}".format(_COMMIT),
        build_file = Label("//bazel:BUILD.test.bazel"),
    )

dxmath_test = module_extension(
    implementation = _dxmath_test_impl,
)
