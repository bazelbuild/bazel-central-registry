"Transition to explicit values of jemalloc's settings"

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

_BOOL_SETTINGS = ["//settings:enable_jet", "//settings/flags:enable_experimental_smallocx", "//settings/flags:enable_fill"]

_SETTINGS = _BOOL_SETTINGS + [
    "//settings:with_test",
    "//settings/flags:enable_lazy_lock",
    "//settings/flags:enable_zone_allocator",
    "//settings/flags:jemalloc_prefix",
    "//settings/platform:lg_page",
    "//settings/platform:lg_vaddr",
]

_SETTING_LABELS = [Label(setting) for setting in _SETTINGS]

def _settings_transition_impl(settings, attr):
    # Only _SETTINGS are outputs of this transition, so a value for any other setting would be dropped without a word
    for label in attr.settings:
        if label not in _SETTING_LABELS:
            fail("with_settings cannot take {} from settings; it takes only {}".format(label, ", ".join(_SETTINGS)))

    result = {}
    for setting in _SETTINGS:
        if Label(setting) in attr.settings:
            value = attr.settings[Label(setting)]
            result[setting] = value == "True" if setting in _BOOL_SETTINGS else value
        else:
            result[setting] = settings[setting]
    return result

settings_transition = transition(
    implementation = _settings_transition_impl,
    inputs = _SETTINGS,
    outputs = _SETTINGS,
)

def _with_settings_impl(ctx):
    target = ctx.attr.src[0]
    providers = [DefaultInfo, CcInfo, InstrumentedFilesInfo, OutputGroupInfo]

    return [target[provider] for provider in providers if provider in target]

with_settings = rule(
    doc = "src built with settings over their configured values",
    implementation = _with_settings_impl,
    attrs = {
        "src": attr.label(cfg = settings_transition),
        "settings": attr.label_keyed_string_dict(
            doc = "Settings to transition to, over their configured values",
            default = {},
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)
