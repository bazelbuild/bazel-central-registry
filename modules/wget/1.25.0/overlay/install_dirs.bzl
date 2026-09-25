"""Expose string build settings as "Make" variables.

Upstream bakes two install-layout paths into the wget program from
`configure --prefix` and friends: `SYSTEM_WGETRC` and `LOCALEDIR`
(src/Makefile.am:35).  Each is a
`-D` on the compile line, not a config.h entry, so the natural Bazel spelling
is a `local_defines` entry.  `local_defines` is subject to "Make" variable
expansion, and a target listed in `toolchains` can supply variables through
`TemplateVariableInfo`; this rule bridges a `string_flag` into that.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _install_dirs_impl(ctx):
    return [platform_common.TemplateVariableInfo({
        variable: setting[BuildSettingInfo].value
        for setting, variable in ctx.attr.settings.items()
    })]

install_dirs = rule(
    doc = "Publishes each string build setting as the named \"Make\" variable.",
    implementation = _install_dirs_impl,
    attrs = {
        "settings": attr.label_keyed_string_dict(
            doc = "Build setting to the \"Make\" variable name it should be exposed as.",
            mandatory = True,
            providers = [BuildSettingInfo],
        ),
    },
)
