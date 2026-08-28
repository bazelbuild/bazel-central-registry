#!/usr/bin/env python3
"""Regenerate FFmpeg component declarations and configure dependencies.

Usage:
    python3 generate_component_defs.py --version 9.0.1.beta.bcr /path/to/ffmpeg

The source tree supplies component declarations, dependency assignments, and
CONFIG_EXTRA. The immutable --policy-version overlay supplies Bazel defaults,
supported platform components, and synthetic component settings. No configure
commands or compiler checks are executed.
"""

from __future__ import annotations

import argparse
import ast
import json
import re
from pathlib import Path

from _overlay_utils import SCRIPTS_DIR, add_version_arg, resolve_overlay_dir
from generate_config_defs import extract_all_lists

DEPENDENCY_FIELDS = ("deps", "deps_any", "select", "suggest", "conflict")

# These settings are part of the Bazel overlay, outside configure's CONFIG_EXTRA.
# Keep them separate from the upstream list so removed CONFIG_EXTRA entries do
# not survive an update merely because the previous overlay contained them.
SYNTHETIC_COMPONENTS = (
    "dwt",
    "error_resilience",
    "h264_metadata",
    "hevc_metadata",
    "lsp",
    "network",
    "pixelutils",
    "videotoolbox_encoder",
)

DECLARATIONS = {
    "bsf": ("libavcodec/bitstream_filters.c", "FFBitStreamFilter", "bsf"),
    "decoder": ("libavcodec/allcodecs.c", "FFCodec", "decoder"),
    "demuxer": ("libavformat/allformats.c", "FFInputFormat", "demuxer"),
    "encoder": ("libavcodec/allcodecs.c", "FFCodec", "encoder"),
    "hwaccel": ("libavcodec/hwaccels.h", "FFHWAccel", "hwaccel"),
    "indev": ("libavdevice/alldevices.c", "FFInputFormat", "demuxer"),
    "muxer": ("libavformat/allformats.c", "FFOutputFormat", "muxer"),
    "outdev": ("libavdevice/alldevices.c", "FFOutputFormat", "muxer"),
    "parser": ("libavcodec/parsers.c", "(?:FFCodecParser|AVCodecParser)", "parser"),
    "protocol": ("libavformat/protocols.c", "URLProtocol", "protocol"),
}


def literal_assignments(text: str) -> dict:
    """Read literal top-level Starlark assignments without executing Starlark."""
    values = {}
    for node in ast.parse(text).body:
        if not isinstance(node, ast.Assign) or not isinstance(node.targets[0], ast.Name):
            continue
        try:
            values[node.targets[0].id] = ast.literal_eval(node.value)
        except (ValueError, TypeError):
            pass
    return values


def configure_dependencies(text: str) -> dict[str, dict[str, list[str]]]:
    """Extract configure's literal component dependency assignments."""
    result: dict[str, dict[str, list[str]]] = {}
    fields = "|".join(DEPENDENCY_FIELDS)
    pattern = re.compile(
        rf'^([a-zA-Z0-9_]+)_({fields})="([^"]*)"',
        re.MULTILINE,
    )
    for match in pattern.finditer(text):
        component, field, value = match.groups()
        names = value.split()
        if any(not re.fullmatch(r"[a-zA-Z0-9_]+", name) for name in names):
            raise ValueError(f"unsupported configure assignment: {match.group(0)}")
        result.setdefault(component, {})[field] = names
    return result


def component_declarations(source: Path) -> tuple[dict[str, list[str]], dict[str, str]]:
    """Read the same registration declarations used by configure's find helpers."""
    types = {}
    for component_type, (filename, c_type, suffix) in DECLARATIONS.items():
        text = (source / filename).read_text(encoding="utf-8")
        names = re.findall(
            rf"^extern const (?:struct )?{c_type}\s+ff_([a-zA-Z0-9_]+)_{suffix};",
            text,
            re.MULTILINE,
        )
        if not names:
            raise ValueError(f"no {component_type} declarations in {filename}")
        types[component_type] = sorted({f"{name}_{component_type}" for name in names})

    filters = re.findall(
        r"^extern const (?:FFFilter|AVFilter) ff_([avfsinkrc]{2,5}_([a-zA-Z0-9_]+));",
        (source / "libavfilter/allfilters.c").read_text(encoding="utf-8"),
        re.MULTILINE,
    )
    if not filters:
        raise ValueError("no filter declarations in libavfilter/allfilters.c")
    symbols = {f"{name}_filter": symbol for symbol, name in filters}
    types["filter"] = sorted(symbols)
    return dict(sorted(types.items())), dict(sorted(symbols.items()))


def format_assignment(name: str, value) -> str:
    """Format component names, lists, and registries as Starlark literals."""
    if isinstance(value, list):
        if name in {"CONFIG_LIST", "ALWAYS_AVAILABLE_LIBS", "PROFILE_EVERYTHING"}:
            return f"{name} = {json.dumps(value)}"
        return name + " = [\n" + "".join(f"    {json.dumps(v)},\n" for v in value) + "]"
    if isinstance(value, dict):
        lines = [name + " = {"]
        for key, item in sorted(value.items()):
            if isinstance(item, list):
                lines.append(f"    {json.dumps(key)}: [")
                lines.extend(f"        {json.dumps(v)}," for v in item)
                lines.append("    ],")
                continue
            if isinstance(item, bool):
                formatted = str(item)
            else:
                formatted = json.dumps(item, sort_keys=True)
            lines.append(f"    {json.dumps(key)}: {formatted},")
        lines.append("}")
        return "\n".join(lines)
    raise TypeError(f"unsupported assignment {name}: {type(value).__name__}")


def policy_definitions(policy_text: str, components: set[str]) -> str:
    """Preserve the policy helpers while dropping names removed by FFmpeg."""
    start = next(
        node.end_lineno
        for node in ast.parse(policy_text).body
        if isinstance(node, ast.Assign)
        and isinstance(node.targets[0], ast.Name)
        and node.targets[0].id == "FILTER_SYMBOL_MAP"
    )
    text = "".join(policy_text.splitlines(keepends=True)[start:]).lstrip("\n")
    lines = text.splitlines(keepends=True)
    edits = []
    filtered = {
        "_PLATFORM_SPECIFIC_DEVICES",
        "_EXTERNAL_COMPONENTS",
        "MACOS_COMPONENTS",
        "LINUX_COMPONENTS",
        "WINDOWS_COMPONENTS",
    }
    for node in ast.parse(text).body:
        if not isinstance(node, ast.Assign) or not isinstance(node.targets[0], ast.Name):
            continue
        name = node.targets[0].id
        if name not in filtered:
            continue
        value = ast.literal_eval(node.value)
        if isinstance(value, dict):
            filtered_value = {key: item for key, item in value.items() if key in components}
        else:
            filtered_value = [item for item in value if item in components]
        if filtered_value != value:
            edits.append((node.lineno - 1, node.end_lineno, format_assignment(name, filtered_value) + "\n"))
    for begin, end, replacement in reversed(edits):
        lines[begin:end] = [replacement]
    return "".join(lines).rstrip()


def generate_definitions(source: Path, policy_text: str, policy_version: str) -> str:
    """Generate registries from one FFmpeg release and one Bazel policy version."""
    policy = literal_assignments(policy_text)
    lists = extract_all_lists(str(source / "configure"))
    dependencies = configure_dependencies((source / "configure").read_text(encoding="utf-8"))
    types, symbols = component_declarations(source)
    registry = {
        name: dict(dependencies.get(name, {}), type=component_type)
        for component_type, names in types.items()
        for name in names
    }
    extras = set(lists["CONFIG_EXTRA"]) | set(SYNTHETIC_COMPONENTS)
    extra_registry = {name: dependencies.get(name, {}) for name in sorted(extras)}
    overlap = set(registry) & extras
    if overlap:
        raise ValueError(f"components also listed in CONFIG_EXTRA: {sorted(overlap)}")

    # ffmpeg_config_checks.bzl enables HAVE_THREADS on every supported platform.
    available = sorted(set(policy["ALWAYS_AVAILABLE_LIBS"]) | {"threads"})
    components = set(registry)
    sections = [
        (
            '"""Generated FFmpeg component declarations and configure dependencies.\n\n'
            "Generated by generate_component_defs.py; do not edit.\n"
            f"Bazel component policy comes from {policy_version}.\n"
            '"""'
        ),
        format_assignment("COMPONENT_TYPES", types),
        format_assignment("COMPONENT_REGISTRY", registry),
        format_assignment("CONFIG_EXTRA_REGISTRY", extra_registry),
        format_assignment("CONFIG_LIST", sorted(set(lists["CONFIG_LIST"]))),
        format_assignment("ALWAYS_AVAILABLE_LIBS", available),
        format_assignment("PROFILE_MINIMAL", [name for name in policy["PROFILE_MINIMAL"] if name in components]),
        format_assignment("PROFILE_EVERYTHING", sorted(components)),
        format_assignment("FILTER_SYMBOL_MAP", symbols),
        policy_definitions(policy_text, components),
    ]
    return "\n\n".join(sections) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ffmpeg_source_root", type=Path)
    parser.add_argument("--policy-version", default="7.1.1.bcr.beta.7")
    parser.add_argument("--check", action="store_true", help="Check the generated file without writing it.")
    add_version_arg(parser)
    args = parser.parse_args()

    overlay = resolve_overlay_dir(args.version)
    policy_file = SCRIPTS_DIR / args.policy_version / "overlay" / "component_defs.bzl"
    output = generate_definitions(
        args.ffmpeg_source_root,
        policy_file.read_text(encoding="utf-8"),
        args.policy_version,
    )
    output_file = overlay / "component_defs.bzl"
    if args.check:
        if output_file.read_text(encoding="utf-8") != output:
            raise SystemExit(f"{output_file} needs regeneration")
    else:
        output_file.write_text(output, encoding="utf-8")
    print(f"  {'checked' if args.check else 'wrote'} {output_file}")


if __name__ == "__main__":
    main()
