def _fail_rule_impl(ctx):
    fail(ctx.attr.message)

_fail_rule = rule(
    implementation = _fail_rule_impl,
    attrs = {
        "message": attr.string(),
    },
)

def make_fail_macro(message):
    return lambda name, **kwargs: _fail_rule(name = name, message = message)
