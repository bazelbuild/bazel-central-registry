"""Build setting helpers for aws_sdk."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _make_variable_from_setting_impl(ctx):
    return [platform_common.TemplateVariableInfo({
        ctx.attr.variable: ctx.attr.setting[BuildSettingInfo].value,
    })]

make_variable_from_setting = rule(
    implementation = _make_variable_from_setting_impl,
    doc = "Exposes a string build setting as a Make variable.",
    attrs = {
        "setting": attr.label(mandatory = True, providers = [BuildSettingInfo]),
        "variable": attr.string(mandatory = True),
    },
)
