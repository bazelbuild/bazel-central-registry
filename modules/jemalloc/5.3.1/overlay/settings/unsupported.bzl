"A target that fails analysis, for a combination of settings jemalloc cannot build"

def _unsupported_impl(ctx):
    fail(ctx.attr.message)

unsupported = rule(
    doc = "Fails analysis with `message`. Selected as a dependency under the config_setting of an unsupported " +
          "combination, so a build that asks for it stops with the reason instead of quietly building without it.",
    implementation = _unsupported_impl,
    attrs = {
        "message": attr.string(
            doc = "What is unsupported, why, and the setting that avoids it.",
            mandatory = True,
        ),
    },
)
