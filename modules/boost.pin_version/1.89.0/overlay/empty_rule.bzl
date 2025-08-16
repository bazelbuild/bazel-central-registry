def _empty_rule_impl(ctx):
    pass

empty_rule = rule(
    implementation = _empty_rule_impl,
)
