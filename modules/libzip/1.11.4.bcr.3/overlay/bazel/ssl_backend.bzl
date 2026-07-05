def _ssl_backend_impl(ctx):
    value = ctx.build_setting_value
    if value not in ["no_ssl", "boringssl", "openssl"]:
        fail("Invalid //:ssl value %r. Use one of: no_ssl, boringssl, openssl." % value)
    return []

ssl_backend = rule(
    implementation = _ssl_backend_impl,
    build_setting = config.string(flag = True),
)
