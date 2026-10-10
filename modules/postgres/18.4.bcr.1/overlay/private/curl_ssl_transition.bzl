"""Incoming-edge transition that pins `@curl//:ssl_lib` to `//:with_ssl`.

`@curl//:curl` carries its own `ssl_lib` flag (defaulted to BoringSSL) that
selects which SSL library it links against. If postgres uses
`--//:with_ssl=openssl` but `--@curl//:ssl_lib` is left at its module
default, the final link will pull in both `@openssl` and `@boringssl` and
trip duplicate-symbol errors (macOS's `ld` rejects them outright; GNU ld
silently picks one).

The fix is to bundle every SSL-touching dep of libpq — `@openssl` /
`@boringssl` themselves and (when `--//:with_libcurl=True`) `@curl//:curl`
— into a single `cc_library`, then wrap that bundle with this transition.
Because every libpq target that needs SSL routes through the wrapped
bundle, there is exactly one path through the build graph that reaches
`@openssl` / `@boringssl`, and it is always in the transitioned config.

Wrapping just `@curl//:curl` instead doesn't work: `:ssl_backend` would
stay in the default config while `@curl//:curl` was transitioned, both
paths would reach `@openssl` at different configs, and Bazel's
`cc_shared_library` machinery would refuse to link the same `libssl`
built in two different configurations.

`--//:with_ssl=none` leaves `@curl//:ssl_lib` at its default since libcurl
isn't linked in that case.
"""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

_WITH_SSL = str(Label("//:with_ssl"))

_CURL_SSL_LIB = str(Label("@curl//:ssl_lib"))

def _pg_ssl_bundle_transition_impl(settings, _attr):
    pg_ssl = settings[_WITH_SSL]
    if pg_ssl == "openssl":
        return {_CURL_SSL_LIB: "openssl"}
    if pg_ssl == "boringssl":
        return {_CURL_SSL_LIB: "boringssl"}
    return {}

_pg_ssl_bundle_transition = transition(
    implementation = _pg_ssl_bundle_transition_impl,
    inputs = [_WITH_SSL],
    outputs = [_CURL_SSL_LIB],
)

def _pg_ssl_bundle_impl(ctx):
    return [ctx.attr.target[0][CcInfo], ctx.attr.target[0][DefaultInfo]]

pg_ssl_bundle = rule(
    implementation = _pg_ssl_bundle_impl,
    doc = "Re-exports a `cc_library` with `@curl//:ssl_lib` forced to match `//:with_ssl`.",
    attrs = {
        "target": attr.label(
            doc = "The `cc_library` bundling libpq's SSL link inputs (openssl/boringssl + optionally @curl).",
            mandatory = True,
            providers = [CcInfo],
            cfg = _pg_ssl_bundle_transition,
        ),
    },
)
