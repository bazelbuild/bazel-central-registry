"""FFmpeg component configuration transitions and conditional source helpers.

Provides macros and rules for:
  - Wrapping library/binary targets under a with_defaults/ transition
    that enables platform-appropriate components
  - Helper to produce conditional srcs from component source maps
"""

load("@rules_cc//cc:defs.bzl", "CcInfo", "cc_binary", "cc_library")
load(
    ":component_defs.bzl",
    "CONFIG_EXTRA_REGISTRY",
    "PROFILE_EVERYTHING",
    "TRANSITIVE_SELECT_CLOSURE",
)
load(
    ":component_resolved.bzl",
    "RESOLVED_COMPONENTS",
    "RESOLVED_DEFAULT",
)
load(
    ":component_srcs.bzl",
    "ALL_SHARED_GROUP_DEFINITIONS",
)

_ALL_COMPONENTS = PROFILE_EVERYTHING + sorted(CONFIG_EXTRA_REGISTRY.keys())

BUILD_VARIANTS = ["", "with_defaults"]

# ---------------------------------------------------------------------------
# Conditional source helper
# ---------------------------------------------------------------------------

def _select_label(comp):
    """Return the config label for a component, using the _or_needed group
    when the component has transitive select ancestors so that source files
    compile automatically when a parent codec is enabled."""
    if comp in TRANSITIVE_SELECT_CLOSURE:
        return "//:enable_{}_or_needed".format(comp)
    return "//:enable_{}_is_true".format(comp)

def component_select_srcs(exclusive_map, shared_list):
    """Build a list of select() expressions for per-component source files.

    Args:
      exclusive_map: Dict mapping component name to list of source files
          exclusive to that component.
      shared_list: List of (component_tuple, file_list) pairs for source
          files shared across multiple components.

    Returns:
      A concatenation of select() values suitable for use in cc_library srcs.
    """
    result = []
    for comp, srcs in exclusive_map.items():
        result = result + select({
            _select_label(comp): srcs,
            "//conditions:default": [],
        })

    groups_by_key = {
        tuple(comps): gid
        for gid, comps in ALL_SHARED_GROUP_DEFINITIONS
    }
    for comps, srcs in shared_list:
        group_id = groups_by_key[tuple(comps)]
        result = result + select({
            "//:{}".format(group_id): srcs,
            "//conditions:default": [],
        })

    return result

# ---------------------------------------------------------------------------
# Transitions
# ---------------------------------------------------------------------------

_TRANSITION_OUTPUTS = [str(Label("//:enable_{}".format(comp))) for comp in _ALL_COMPONENTS]

def _with_defaults_impl(settings, attr):
    key = "{}-{}".format(attr.os, attr.cpu)
    resolved = RESOLVED_COMPONENTS.get(key, RESOLVED_DEFAULT)

    output = {}
    for comp in _ALL_COMPONENTS:
        label = str(Label("//:enable_{}".format(comp)))
        user_value = settings[label]
        output[label] = user_value or resolved.get(comp, False)

    for child, ancestors in TRANSITIVE_SELECT_CLOSURE.items():
        child_label = str(Label("//:enable_{}".format(child)))
        if output.get(child_label, False):
            continue
        for ancestor in ancestors:
            ancestor_label = str(Label("//:enable_{}".format(ancestor)))
            if output.get(ancestor_label, False):
                output[child_label] = True
                break

    return output

_with_defaults_transition = transition(
    implementation = _with_defaults_impl,
    inputs = _TRANSITION_OUTPUTS,
    outputs = _TRANSITION_OUTPUTS,
)

# ---------------------------------------------------------------------------
# Wrapper rules
# ---------------------------------------------------------------------------

def _forward_library_impl(ctx):
    target = ctx.attr.target[0]
    providers = [target[DefaultInfo]]
    if CcInfo in target:
        providers.append(target[CcInfo])
    if OutputGroupInfo in target:
        providers.append(target[OutputGroupInfo])
    if InstrumentedFilesInfo in target:
        providers.append(target[InstrumentedFilesInfo])
    return providers

with_defaults_library = rule(
    doc = "Forwards a cc_library target built with platform-appropriate component defaults.",
    implementation = _forward_library_impl,
    attrs = {
        "cpu": attr.string(
            doc = "Target CPU, resolved via select() on @platforms//cpu. Reserved for future use.",
        ),
        "os": attr.string(
            doc = "Target OS, resolved via select() on @platforms//os. Used by the transition.",
        ),
        "target": attr.label(
            doc = "The cc_library target to rebuild under platform-aware defaults.",
            cfg = _with_defaults_transition,
            mandatory = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = Label("@bazel_tools//tools/allowlists/function_transition_allowlist"),
        ),
    },
)

def _forward_binary_impl(ctx):
    target = ctx.attr.target[0]
    original = target[DefaultInfo]
    executable = original.files_to_run.executable
    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(output = out, target_file = executable)

    providers = [DefaultInfo(
        executable = out,
        files = depset([out]),
        runfiles = original.default_runfiles,
    )]
    if CcInfo in target:
        providers.append(target[CcInfo])
    if OutputGroupInfo in target:
        providers.append(target[OutputGroupInfo])
    if InstrumentedFilesInfo in target:
        providers.append(target[InstrumentedFilesInfo])

    return providers

with_defaults_binary = rule(
    doc = "Forwards a cc_binary target built with platform-appropriate component defaults.",
    implementation = _forward_binary_impl,
    attrs = {
        "cpu": attr.string(
            doc = "Target CPU, resolved via select() on @platforms//cpu. Reserved for future use.",
        ),
        "os": attr.string(
            doc = "Target OS, resolved via select() on @platforms//os. Used by the transition.",
        ),
        "target": attr.label(
            doc = "The cc_binary target to rebuild under platform-aware defaults.",
            cfg = _with_defaults_transition,
            executable = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = Label("@bazel_tools//tools/allowlists/function_transition_allowlist"),
        ),
    },
    executable = True,
)

# ---------------------------------------------------------------------------
# Variant macros
# ---------------------------------------------------------------------------

def _os_select():
    """Returns a select() resolving the target OS to a string."""
    return select({
        "@platforms//os:linux": "linux",
        "@platforms//os:macos": "macos",
        "@platforms//os:windows": "windows",
        "//conditions:default": "unknown",
    })

def _cpu_select():
    """Returns a select() resolving the target CPU to a string."""
    return select({
        "@platforms//cpu:aarch64": "aarch64",
        "@platforms//cpu:x86_64": "x86_64",
        "//conditions:default": "unknown",
    })

def cc_variant_library(name, **kwargs):
    """Like cc_library, but also emits a with_defaults/ variant.

    The with_defaults/ variant uses a transition to enable all components
    appropriate for the target platform (OS and CPU).

    Args:
      name: Target name, forwarded to cc_library.
      **kwargs: All remaining arguments are forwarded to cc_library.
    """
    cc_library(name = name, **kwargs)
    visibility = kwargs.get("visibility")
    with_defaults_library(
        name = "with_defaults/{}".format(name),
        target = ":{}".format(name),
        os = _os_select(),
        cpu = _cpu_select(),
        visibility = visibility,
    )

def cc_variant_binary(name, **kwargs):
    """Like cc_binary, but also emits a with_defaults/ variant.

    The with_defaults/ variant uses a transition to enable all components
    appropriate for the target platform (OS and CPU).

    Args:
      name: Target name, forwarded to cc_binary.
      **kwargs: All remaining arguments are forwarded to cc_binary.
    """
    cc_binary(name = name, **kwargs)
    visibility = kwargs.get("visibility")
    with_defaults_binary(
        name = "with_defaults/{}".format(name),
        target = ":{}".format(name),
        os = _os_select(),
        cpu = _cpu_select(),
        visibility = visibility,
    )

def variant_prefix(variant):
    """Returns 'variant/' for non-empty variant, '' otherwise.

    Convenience helper for list comprehensions in test BUILD files:
        deps = ["//:{}avutil".format(variant_prefix(v))]
    """
    return variant + "/" if variant else ""
