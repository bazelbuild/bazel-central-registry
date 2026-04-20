#!/usr/bin/env python3
"""Pre-compute resolved component profiles from the static dependency graph.

Reads component_defs.bzl (COMPONENT_REGISTRY, CONFIG_EXTRA_REGISTRY, profiles,
and available-library lists), resolves transitive select/suggest edges and prunes
components with unsatisfiable deps, then writes component_resolved.bzl with
one dict per (OS, CPU) combination.

Usage:
    python3 generate_resolved_profiles.py [--version 7.1.1.bcr.beta.5]

Must be re-run whenever component_defs.bzl changes (new components, changed
dependency edges, or updated profiles).
"""

import argparse
import ast
import os
import re
import sys

from _overlay_utils import add_version_arg, resolve_overlay_dir


# ---------------------------------------------------------------------------
# Platform matrix
# ---------------------------------------------------------------------------

OS_NAMES = ["linux", "macos", "windows"]
CPU_NAMES = ["aarch64", "x86_64"]


# ---------------------------------------------------------------------------
# Starlark data extraction
# ---------------------------------------------------------------------------


def _extract_block(text: str, var_name: str) -> str:
    """Extract the RHS of a top-level assignment ``var_name = ...``.

    Handles multi-line dicts, lists, and list comprehensions by counting
    bracket depth.
    """
    pattern = re.compile(
        r"^" + re.escape(var_name) + r"\s*=\s*",
        re.MULTILINE,
    )
    m = pattern.search(text)
    if m is None:
        raise ValueError(f"variable {var_name!r} not found")

    start = m.end()
    openers = {"(", "[", "{"}
    closers = {")", "]", "}"}
    depth = 0
    i = start
    in_string = None
    while i < len(text):
        ch = text[i]
        if in_string:
            if ch == "\\" and i + 1 < len(text):
                i += 2
                continue
            if ch == in_string:
                in_string = None
            i += 1
            continue
        if ch in ('"', "'"):
            if text[i : i + 3] in ('"""', "'''"):
                in_string = text[i : i + 3]
                i += 3
                continue
            in_string = ch
            i += 1
            continue
        if ch == "#":
            nl = text.find("\n", i)
            i = nl + 1 if nl != -1 else len(text)
            continue
        if ch in openers:
            depth += 1
        elif ch in closers:
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
        i += 1

    raise ValueError(f"unterminated expression for {var_name!r}")


def _safe_eval(expr: str):
    """Evaluate a Python-compatible Starlark literal (dict/list/set/string)."""
    return ast.literal_eval(expr)


def _extract_var(text: str, var_name: str):
    """Extract and evaluate a top-level variable assignment."""
    block = _extract_block(text, var_name)
    try:
        return _safe_eval(block)
    except (ValueError, SyntaxError) as exc:
        raise ValueError(f"cannot evaluate {var_name!r}: {exc}\n  block starts with: {block[:120]!r}") from exc


# ---------------------------------------------------------------------------
# Dependency resolution (mirrors the old component_resolve.bzl)
# ---------------------------------------------------------------------------


def _get_entry(comp, component_registry, extra_registry):
    if comp in component_registry:
        return component_registry[comp]
    if comp in extra_registry:
        return extra_registry[comp]
    return {}


def resolve_components(
    enabled_components: list[str],
    component_registry: dict,
    extra_registry: dict,
    available_libs: list[str],
) -> dict[str, bool]:
    """Resolve component dependencies returning the full enabled-flag map.

    Two-phase algorithm:
      Phase 1 -- propagate select/suggest edges to a fixpoint (monotonically
                 increasing, so guaranteed to converge).
      Phase 2 -- prune components whose deps/selects are not satisfiable
                 (monotonically decreasing, no oscillation possible).
    """
    state: dict[str, bool] = {}
    for comp in component_registry:
        state[comp] = False
    for comp in extra_registry:
        state[comp] = False
    for lib in available_libs:
        state[lib] = True
    for comp in enabled_components:
        if comp in state:
            state[comp] = True

    # Phase 1: propagate
    changed = True
    while changed:
        changed = False
        for comp, enabled in list(state.items()):
            if not enabled:
                continue
            entry = _get_entry(comp, component_registry, extra_registry)
            for sel in entry.get("select", []):
                if sel in state and not state[sel]:
                    state[sel] = True
                    changed = True
            for sug in entry.get("suggest", []):
                if sug in state and not state[sug]:
                    state[sug] = True
                    changed = True

    # Phase 2: prune
    changed = True
    while changed:
        changed = False
        for comp, enabled in list(state.items()):
            if not enabled:
                continue
            entry = _get_entry(comp, component_registry, extra_registry)

            deps = entry.get("deps", [])
            if deps and not all(state.get(d, False) for d in deps):
                state[comp] = False
                changed = True
                continue

            deps_any = entry.get("deps_any", [])
            if deps_any and not any(state.get(d, False) for d in deps_any):
                state[comp] = False
                changed = True
                continue

            conflicts = entry.get("conflict", [])
            if conflicts and any(state.get(d, False) for d in conflicts):
                state[comp] = False
                changed = True
                continue

            selects = entry.get("select", [])
            if selects and not all(state.get(d, False) for d in selects):
                state[comp] = False
                changed = True
                continue

    return state


# ---------------------------------------------------------------------------
# Profile computation (mirrors component_defs.bzl helpers)
# ---------------------------------------------------------------------------


def compute_configure_defaults(
    profile_everything: list[str],
    hwapi_patterns: list[str],
    platform_specific_devices: dict,
    external_components: dict,
) -> list[str]:
    """Replicate ``_is_configure_default`` from component_defs.bzl."""
    result = []
    for comp in profile_everything:
        if comp.startswith("lib"):
            continue
        if any(pat in comp for pat in hwapi_patterns):
            continue
        if comp in platform_specific_devices:
            continue
        if comp in external_components:
            continue
        result.append(comp)
    return result


# ---------------------------------------------------------------------------
# Output generation
# ---------------------------------------------------------------------------


def format_dict(name: str, state: dict[str, bool], indent: str = "    ") -> str:
    """Format a dict as a Starlark assignment with sorted keys."""
    lines = [f"{name} = {{"]
    for key in sorted(state.keys()):
        lines.append(f'{indent}"{key}": {str(state[key])},')
    lines.append("}")
    return "\n".join(lines)


def generate_output(
    os_profiles: dict[str, dict[str, bool]],
    os_cpu_profiles: dict[str, dict[str, bool]],
    default_profile: dict[str, bool],
) -> str:
    """Produce the full component_resolved.bzl content."""
    sections: list[str] = []

    sections.append(
        '"""Pre-computed component resolution profiles.\n'
        "\n"
        "These profiles are consumed by the with_defaults/ transition in\n"
        "component_flags.bzl.  When a target is built via with_defaults/,\n"
        "the transition looks up the matching (OS, CPU) key in\n"
        "RESOLVED_COMPONENTS and sets every component bool_flag accordingly.\n"
        "Targets built without with_defaults/ are unaffected.\n"
        "\n"
        "Generated by generate_resolved_profiles.py -- do not edit.\n"
        '"""'
    )

    # Private per-OS base profiles
    for os_name in OS_NAMES:
        key = os_name
        if key in os_profiles:
            sections.append("")
            sections.append(format_dict(f"_RESOLVED_{os_name.upper()}", os_profiles[key]))

    # Default fallback
    sections.append("")
    sections.append(format_dict("_RESOLVED_DEFAULT", default_profile))

    # Public per-(OS, CPU) profiles
    sections.append("")
    for os_name in OS_NAMES:
        for cpu in CPU_NAMES:
            combo_key = f"{os_name}-{cpu}"
            public_name = f"RESOLVED_{os_name.upper()}_{cpu.upper()}"
            if combo_key in os_cpu_profiles:
                # CPU-specific override exists -- emit full dict
                sections.append(format_dict(public_name, os_cpu_profiles[combo_key]))
                sections.append("")
            else:
                # No CPU-specific difference -- alias the OS base
                sections.append(f"{public_name} = _RESOLVED_{os_name.upper()}")
                sections.append("")

    # RESOLVED_COMPONENTS map
    sections.append("RESOLVED_COMPONENTS = {")
    for os_name in OS_NAMES:
        for cpu in CPU_NAMES:
            public_name = f"RESOLVED_{os_name.upper()}_{cpu.upper()}"
            sections.append(f'    "{os_name}-{cpu}": {public_name},')
    sections.append("}")
    sections.append("")

    # Default for unknown platforms
    sections.append("RESOLVED_DEFAULT = _RESOLVED_DEFAULT")
    sections.append("")

    return "\n".join(sections)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="Pre-compute resolved FFmpeg component profiles.",
    )
    add_version_arg(parser)
    args = parser.parse_args()

    overlay = resolve_overlay_dir(args.version)
    defs_path = os.path.join(overlay, "component_defs.bzl")
    output_path = os.path.join(overlay, "component_resolved.bzl")

    with open(defs_path) as f:
        text = f.read()

    # Extract data from component_defs.bzl
    component_registry = _extract_var(text, "COMPONENT_REGISTRY")
    extra_registry = _extract_var(text, "CONFIG_EXTRA_REGISTRY")
    available_libs = _extract_var(text, "ALWAYS_AVAILABLE_LIBS")
    profile_everything = _extract_var(text, "PROFILE_EVERYTHING")
    hwapi_patterns = _extract_var(text, "_HWAPI_PATTERNS")
    platform_devices = _extract_var(text, "_PLATFORM_SPECIFIC_DEVICES")
    external_comps = _extract_var(text, "_EXTERNAL_COMPONENTS")

    os_component_lists = {
        "linux": _extract_var(text, "LINUX_COMPONENTS"),
        "macos": _extract_var(text, "MACOS_COMPONENTS"),
        "windows": _extract_var(text, "WINDOWS_COMPONENTS"),
    }

    defaults = compute_configure_defaults(
        profile_everything,
        hwapi_patterns,
        platform_devices,
        external_comps,
    )

    # Resolve per-OS profiles (common across CPUs)
    os_profiles: dict[str, dict[str, bool]] = {}
    for os_name in OS_NAMES:
        enabled = defaults + os_component_lists.get(os_name, [])
        state = resolve_components(
            enabled,
            component_registry,
            extra_registry,
            available_libs,
        )
        os_profiles[os_name] = state

        enabled_count = sum(1 for v in state.values() if v)
        pruned = [c for c in enabled if c in state and not state[c]]
        print(
            f"  {os_name}: {enabled_count}/{len(state)} components enabled ({len(pruned)} pruned)",
            file=sys.stderr,
        )
        for c in sorted(pruned):
            entry = _get_entry(c, component_registry, extra_registry)
            deps = entry.get("deps", [])
            missing = [d for d in deps if not state.get(d, False)]
            print(f"    pruned {c}: missing deps {missing}", file=sys.stderr)

    # Default profile (no OS-specific components)
    default_state = resolve_components(
        defaults,
        component_registry,
        extra_registry,
        available_libs,
    )
    enabled_count = sum(1 for v in default_state.values() if v)
    pruned = [c for c in defaults if c in default_state and not default_state[c]]
    print(
        f"  default: {enabled_count}/{len(default_state)} components enabled ({len(pruned)} pruned)",
        file=sys.stderr,
    )

    # Per-(OS, CPU) profiles -- currently identical to the OS base since
    # there are no CPU-specific component lists.  When CPU-specific lists
    # are added to component_defs.bzl, extend the enabled set here.
    os_cpu_profiles: dict[str, dict[str, bool]] = {}
    # (empty for now -- all combos alias their OS base)

    output = generate_output(os_profiles, os_cpu_profiles, default_state)

    with open(output_path, "w") as f:
        f.write(output)
    print(f"  wrote {output_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
