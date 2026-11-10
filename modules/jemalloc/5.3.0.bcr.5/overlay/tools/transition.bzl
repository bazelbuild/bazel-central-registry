"Transition build and platform settings"

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

# configure.ac's host table arm for *-*-darwin* and *-*-ios*: "darwin" for every Apple OS.
PLATFORM = select({
    "@platforms//os:android": "android",
    "@platforms//os:freebsd": "freebsd",
    "@platforms//os:linux": "linux",
    "@platforms//os:windows": "windows",
} | {
    os: "darwin"
    for os in [
        "@platforms//os:ios",
        "@platforms//os:macos",
        "@platforms//os:tvos",
        "@platforms//os:visionos",
        "@platforms//os:watchos",
    ]
} | {"//conditions:default": "unknown"})

# The CPU class the platform defaults read. aarch64, ppc64le and x86_64 have defaults of their own; any other CPU is
# classed by its pointer width, and a CPU whose width @platforms leaves ambiguous (ppc) or that is not listed is
# "unknown".
CPU = select({
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
} | {"//conditions:default": "unknown"})

# Assume typical defaults for target platforms. A "<platform>-<cpu>" key takes precedence over a "<platform>" key, and
# that over a "*-<cpu>" key. A setting without a "default" key must be set explicitly where no other key matches.
_PLATFORM_DEFAULTS = {
    "//settings/flags:enable_lazy_lock": {"freebsd": "yes", "default": "no"},
    "//settings/flags:enable_zone_allocator": {"darwin": "yes", "default": "no"},
    # configure.ac's --with-jemalloc-prefix default: "je_" for the macho and pecoff ABIs, "" otherwise.
    "//settings/flags:jemalloc_prefix": {"darwin": "je_", "windows": "je_", "default": ""},
    # 64K pages on aarch64 Linux and Android and ppc64le Linux: LG_PAGE must be at least the kernel's page size or
    # pages_boot fails, and aarch64 kernels use 4K, 16K or 64K pages, ppc64le kernels 4K or 64K. configure.ac's
    # cross-compiling answer is 12; Debian and Fedora build their jemalloc packages for these CPUs with
    # --with-lg-page=16.
    "//settings/platform:lg_page": {
        "android-aarch64": "16",
        "darwin": "14",
        "linux-aarch64": "16",
        "linux-ppc64le": "16",
        "default": "12",
    },
    # configure.ac's LG_VADDR: 48 on aarch64, 57 on x86_64 (its cross-compiling answer; natively it runs CPUID), and the
    # pointer width on any other CPU. A CPU of unknown width has no default, as the value is a fact about the target.
    "//settings/platform:lg_vaddr": {
        "*-aarch64": "48",
        "*-other_32_bit": "32",
        "*-other_64_bit": "64",
        "*-ppc64le": "64",
        "*-x86_64": "57",
    },
}

_BOOL_SETTINGS = ["//settings:enable_jet", "//settings/flags:enable_experimental_smallocx", "//settings/flags:enable_fill"]

_SETTINGS = _BOOL_SETTINGS + ["//settings:with_test"] + list(_PLATFORM_DEFAULTS)

_SETTING_LABELS = [Label(setting) for setting in _SETTINGS]

_PREFIX_RESOLVED = "//settings/flags:jemalloc_prefix_resolved"

_CPREFIX = "//settings/flags:jemalloc_cprefix"

def _platform_constraints_transition_impl(settings, attr):
    # Only _SETTINGS are taken from settings. Any other key is either not an output of this transition or, like
    # jemalloc_prefix_resolved and jemalloc_cprefix, derived from jemalloc_prefix below, so its value would be dropped
    # without a word.
    for label in attr.settings:
        if label not in _SETTING_LABELS:
            fail("transition_default_constraints cannot take {} from settings; it takes only {}".format(label, ", ".join(_SETTINGS)))

    result = {}
    for setting in _SETTINGS:
        if Label(setting) in attr.settings:
            value = attr.settings[Label(setting)]
            if setting in _BOOL_SETTINGS:
                value = value == "True"
        else:
            value = settings[setting]
        if value == "__auto__" and setting in _PLATFORM_DEFAULTS:
            defaults = _PLATFORM_DEFAULTS[setting]
            value = defaults.get(
                "{}-{}".format(attr.platform, attr.cpu),
                defaults.get(attr.platform, defaults.get("*-" + attr.cpu, defaults.get("default"))),
            )
            if value == None:
                fail("{} has no default for the {} platform with a CPU of class {}; set it explicitly".format(
                    setting,
                    attr.platform,
                    attr.cpu,
                ))
        result[setting] = value

    # configure.ac: AC_MSG_ERROR([--enable-zone-allocator is only supported on Darwin]). Without it, zone.c stops at
    # its own #error once compiled.
    if result["//settings/flags:enable_zone_allocator"] == "yes" and attr.platform != "darwin":
        fail("//settings/flags:enable_zone_allocator=yes is only supported on Darwin, as configure's " +
             "--enable-zone-allocator; the target platform is {}".format(attr.platform))

    result[_PREFIX_RESOLVED] = result["//settings/flags:jemalloc_prefix"]

    # Equivalent of JEMALLOC_CPREFIX=`echo ${JEMALLOC_PREFIX} | tr "a-z" "A-Z"`
    result[_CPREFIX] = result[_PREFIX_RESOLVED].upper()

    return result

platform_constraints_transition = transition(
    implementation = _platform_constraints_transition_impl,
    inputs = _SETTINGS + [_CPREFIX],
    outputs = _SETTINGS + [_PREFIX_RESOLVED, _CPREFIX],
)

def _transition_default_constraints_impl(ctx):
    target = ctx.attr.src[0]
    providers = [DefaultInfo, CcInfo, InstrumentedFilesInfo, OutputGroupInfo]

    return [target[provider] for provider in providers if provider in target]

transition_default_constraints = rule(
    doc = "Configure detects target platform constraints. The target platform should declare these, but " +
          "intelligent defaults can be set for the majority of cases.",
    implementation = _transition_default_constraints_impl,
    attrs = {
        "src": attr.label(cfg = platform_constraints_transition),
        "cpu": attr.string(
            doc = "The CPU class the transition reads, alongside platform, to apply unset defaults",
            mandatory = True,
            values = [
                "aarch64",
                "other_32_bit",
                "other_64_bit",
                "ppc64le",
                "unknown",
                "x86_64",
            ],
        ),
        "platform": attr.string(
            doc = "Hack to inject platform constraints into the transition to apply unset defaults",
            mandatory = True,
            values = [
                "android",
                "freebsd",
                "linux",
                "darwin",
                "windows",
                "unknown",
            ],
        ),
        "settings": attr.label_keyed_string_dict(
            doc = "Settings to transition to, over both their configured values and the platform defaults. Only the " +
                  "settings it resolves are accepted; jemalloc_prefix_resolved and jemalloc_cprefix are derived from " +
                  "jemalloc_prefix.",
            default = {},
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)
