"""configure's defaults for the settings that default to "__auto__", resolved from the target platform."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

# The Apple OSes, the "darwin" platform
DARWIN_OSES = ["ios", "macos", "tvos", "visionos", "watchos"]

# The OSes whose default jemalloc prefix is je_: configure.ac's macho and pecoff ABIs
JE_PREFIX_OSES = DARWIN_OSES + ["windows"]

def _resolved_setting_impl(ctx):
    value = ctx.attr.setting[BuildSettingInfo].value
    if value == "__auto__":
        # A "<platform>-<cpu>" key takes precedence over a "<platform>" key, and that over a "*-<cpu>" key
        defaults = ctx.attr.defaults
        value = defaults.get(
            "{}-{}".format(ctx.attr.platform, ctx.attr.cpu),
            defaults.get(ctx.attr.platform, defaults.get("*-" + ctx.attr.cpu, defaults.get("default"))),
        )
        if value == None:
            fail("{} has no default for the {} platform with a CPU of class {}; set it explicitly".format(
                ctx.attr.setting.label,
                ctx.attr.platform,
                ctx.attr.cpu,
            ))
    if ctx.attr.upper:
        value = value.upper()
    providers = [BuildSettingInfo(value = value)]
    if ctx.attr.make_variable:
        providers.append(platform_common.TemplateVariableInfo({ctx.attr.make_variable: value}))
    return providers

_resolved_setting = rule(
    implementation = _resolved_setting_impl,
    attrs = {
        "cpu": attr.string(
            doc = "The target's CPU class, a defaults key's <cpu>",
            mandatory = True,
            values = ["aarch64", "other_32_bit", "other_64_bit", "ppc64le", "unknown", "x86_64"],
        ),
        "defaults": attr.string_dict(
            doc = "Values for __auto__, keyed by \"<platform>-<cpu>\", \"<platform>\", \"*-<cpu>\" or \"default\".",
        ),
        "make_variable": attr.string(),
        "platform": attr.string(
            doc = "The target's platform as configure.ac's host table names it, a defaults key's <platform>",
            mandatory = True,
            values = ["android", "darwin", "freebsd", "linux", "unknown", "windows"],
        ),
        "setting": attr.label(mandatory = True, providers = [BuildSettingInfo]),
        "upper": attr.bool(doc = "Uppercase the value, as configure's `tr \"a-z\" \"A-Z\"`."),
    },
)

def resolved_setting(name, setting, defaults = {}, make_variable = None, upper = False, **kwargs):
    """setting's value as BuildSettingInfo, with __auto__ resolved from defaults for the target platform.

    Args:
      name: The target's name.
      setting: A build setting, or another resolved_setting.
      defaults: Values for __auto__, keyed by "<platform>-<cpu>", "<platform>", "*-<cpu>" or "default".
      make_variable: The make variable the value is also provided as.
      upper: Uppercase the value.
      **kwargs: Common attributes.
    """
    _resolved_setting(
        name = name,
        # The CPU class the platform defaults read. aarch64, ppc64le and x86_64 have defaults of their own; any other
        # CPU is classed by its pointer width, and a CPU whose width @platforms leaves ambiguous (ppc) or that is not
        # listed is "unknown".
        cpu = select({
            "@platforms//cpu:aarch64": "aarch64",
            "@platforms//cpu:ppc64le": "ppc64le",
            "@platforms//cpu:x86_64": "x86_64",
        } | {
            cpu: "other_64_bit"
            for cpu in [
                "@platforms//cpu:arm64e",
                "@platforms//cpu:cortex-r82",
                "@platforms//cpu:mips64",
                "@platforms//cpu:riscv64",
                "@platforms//cpu:s390x",
                "@platforms//cpu:wasm64",
            ]
        } | {
            cpu: "other_32_bit"
            for cpu in [
                "@platforms//cpu:aarch32",
                "@platforms//cpu:arm64_32",
                "@platforms//cpu:armv6-m",
                "@platforms//cpu:armv7",
                "@platforms//cpu:armv7-m",
                "@platforms//cpu:armv7e-m",
                "@platforms//cpu:armv7e-mf",
                "@platforms//cpu:armv7k",
                "@platforms//cpu:armv8-m",
                "@platforms//cpu:cortex-r52",
                "@platforms//cpu:i386",
                "@platforms//cpu:ppc32",
                "@platforms//cpu:riscv32",
                "@platforms//cpu:wasm32",
                "@platforms//cpu:x86_32",
            ]
        } | {"//conditions:default": "unknown"}),
        defaults = defaults,
        make_variable = make_variable,
        # configure.ac's host table arm for *-*-darwin* and *-*-ios*: "darwin" for every Apple OS.
        platform = select({
            "@platforms//os:android": "android",
            "@platforms//os:freebsd": "freebsd",
            "@platforms//os:linux": "linux",
            "@platforms//os:windows": "windows",
        } | {
            "@platforms//os:" + os: "darwin"
            for os in DARWIN_OSES
        } | {"//conditions:default": "unknown"}),
        setting = setting,
        upper = upper,
        **kwargs
    )
