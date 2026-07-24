def _flag_consistency_check_impl(ctx):
    if ctx.attr.crypto.label.repo_name != ctx.attr.ssl.label.repo_name:
        fail("When configuring --@ssl_lib//:ssl_lib to a non-default value you must also set --@ssl_lib//:crypto_lib to point to the matching library in the same module.")
    return [DefaultInfo()]

flag_consistency_check = rule(
    implementation = _flag_consistency_check_impl,
    attrs = {
        "crypto": attr.label(),
        "ssl": attr.label(),
    },
)
