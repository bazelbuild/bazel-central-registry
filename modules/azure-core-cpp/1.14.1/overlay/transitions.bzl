"""Transitions for configuring the build settings of azure-core-cpp deps."""

def _use_openssl_impl(_settings, _attr):
    return {"@curl//:ssl_lib": "openssl"}

use_openssl = transition(
    implementation = _use_openssl_impl,
    inputs = [],
    outputs = ["@curl//:ssl_lib"],
)

def _curl_with_openssl_impl(ctx):
    return [ctx.attr.curl_target[0][CcInfo]]

curl_with_openssl = rule(
    implementation = _curl_with_openssl_impl,
    attrs = {
        "curl_target": attr.label(mandatory = True, cfg = use_openssl),
    },
)
