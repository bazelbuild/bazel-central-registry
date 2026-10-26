"""Builds SFML's TLS/SSH dependencies in the configuration SFML requires.

SFML's network module needs Mbed TLS compiled with MBEDTLS_THREADING_C and
MBEDTLS_THREADING_ALT (upstream patches mbedtls_config.h the same way), and libssh2
using Mbed TLS as its crypto backend. The BCR mbedtls and libssh2 modules expose these
as build settings, so instead of asking every user to set them on the command line,
this rule applies them with a transition on its `deps` and forwards the resulting
CcInfo to the network library.
"""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

_MBEDTLS_CONFIG = str(Label("@mbedtls//:mbedtls_config"))
_LIBSSH2_CRYPTO_BACKEND = str(Label("@libssh2//:crypto_backend"))
_SFML_MBEDTLS_CONFIG = str(Label("//:mbedtls_config"))

def _tls_transition_impl(_settings, _attr):
    return {
        _MBEDTLS_CONFIG: _SFML_MBEDTLS_CONFIG,
        _LIBSSH2_CRYPTO_BACKEND: "mbedtls",
    }

_tls_transition = transition(
    implementation = _tls_transition_impl,
    inputs = [],
    outputs = [
        _MBEDTLS_CONFIG,
        _LIBSSH2_CRYPTO_BACKEND,
    ],
)

def _sfml_tls_deps_impl(ctx):
    return [cc_common.merge_cc_infos(
        cc_infos = [dep[CcInfo] for dep in ctx.attr.deps],
    )]

sfml_tls_deps = rule(
    implementation = _sfml_tls_deps_impl,
    attrs = {
        "deps": attr.label_list(
            cfg = _tls_transition,
            providers = [CcInfo],
        ),
    },
    provides = [CcInfo],
)
