#!/usr/bin/env python3
"""Parse FFmpeg Makefiles and generate component_srcs.bzl.

Extracts OBJS-$(CONFIG_*) mappings from each library's Makefile (and its
sub-Makefiles) to produce a Starlark file with per-library source-file
dictionaries consumed by the Bazel build.

Usage:
    python3 generate_component_srcs.py [--version 9.0.1] /path/to/ffmpeg

The script reads PROFILE_EVERYTHING and CONFIG_EXTRA_REGISTRY from
component_defs.bzl, and fixed CONFIG_* values from config.h.in, in the
version overlay directory and writes component_srcs.bzl to the same overlay.
Shared-group IDs and sections come from the immutable --reference-version
overlay, not the output being regenerated.
"""

from __future__ import annotations

import argparse
import ast
import re
import sys
from collections import defaultdict
from collections.abc import Iterator
from pathlib import Path
from typing import NamedTuple

from _overlay_utils import add_version_arg, resolve_overlay_dir

CONFIG_EXTRA_SET: set[str] = set()
STATIC_CONFIG_SET: set[str] = set()

ARCH_DIRS: set[str] = {
    "x86",
    "aarch64",
    "arm",
    "ppc",
    "mips",
    "loongarch",
    "riscv",
    "neon",
    "wasm",
}

# Match config.h.in and the CPU targets supported by BUILD.bazel. SVE and SME
# sources require assembler checks and source selection that the overlay does
# not provide, so only the existing ARMV8, NEON, and X86ASM groups are included.
OBJECT_PREFIXES = {None, "ARMV8", "NEON", "X86ASM"}
MAKEFILE_FEATURES = {
    "ARCH_X86_64": True,
    "CONFIG_GPL": False,
    "CONFIG_HARDCODED_TABLES": False,
    "CONFIG_SMALL": False,
    "CONFIG_UNSTABLE": False,
}


class LibInfo(NamedTuple):
    """Metadata for one FFmpeg library directory."""

    name: str
    dir: str
    sub_makefiles: list[str]


LIBS: list[LibInfo] = [
    LibInfo("avcodec", "libavcodec", ["aac", "hevc", "opus", "vvc", "bsf"]),
    LibInfo("avformat", "libavformat", []),
    LibInfo("avfilter", "libavfilter", ["dnn"]),
    LibInfo("avdevice", "libavdevice", []),
]

EXTERNAL_FILES_TO_SKIP: set[str] = {
    "d3d12va_encode",
    "qsv",
    "qsvdec",
    "qsvenc",
    "qsvvpp",
    "vaapi_encode",
    "vulkan_encode",
}

# BUILD.bazel selects network.c and the TLS backend together with their deps.
MANUAL_SRCS = {
    "libavformat/network.c",
    "libavformat/tls_openssl.c",
    "libavformat/tls_mbedtls.c",
}


def load_registry_keys(defs_path: Path, name: str) -> set[str]:
    """Read the keys of a literal list or dictionary in component_defs.bzl."""
    for node in ast.parse(defs_path.read_text(encoding="utf-8")).body:
        if isinstance(node, ast.Assign) and any(
            isinstance(target, ast.Name) and target.id == name for target in node.targets
        ):
            return set(ast.literal_eval(node.value))
    raise ValueError(f"Could not find {name} in {defs_path}")


def load_static_configs(template_path: Path) -> set[str]:
    """Read CONFIG_* definitions fixed to 1 by config.h.in."""
    return {
        name.lower()
        for name in re.findall(
            r"^#define CONFIG_([A-Z0-9_]+)[ \t]+1[ \t]*$",
            template_path.read_text(encoding="utf-8"),
            re.MULTILINE,
        )
    }


def load_profile_everything(defs_path: Path | None = None) -> set[str]:
    """Parse PROFILE_EVERYTHING from component_defs.bzl.

    Args:
        defs_path: Explicit path to component_defs.bzl.  Falls back to
            the copy next to this script when *None*.
    """
    if defs_path is None:
        defs_path = Path(__file__).parent / "component_defs.bzl"
    return load_registry_keys(defs_path, "PROFILE_EVERYTHING")


PROFILE_EVERYTHING_SET: set[str] = set()


# -- Makefile parsing ---------------------------------------------------------


def _makefile_lines(path: Path) -> Iterator[str]:
    """Join continuations and apply the static Makefile conditionals we use."""
    conditions: list[bool] = []
    for line in path.read_text(encoding="utf-8").replace("\\\n", " ").splitlines():
        line = line.split("#", 1)[0].strip()
        match = re.fullmatch(r"(ifdef|ifndef) (\w+)", line)
        if match:
            directive, feature = match.groups()
            if feature not in MAKEFILE_FEATURES:
                raise ValueError(f"Unsupported conditional in {path}: {line}")
            value = MAKEFILE_FEATURES[feature]
            conditions.append(value if directive == "ifdef" else not value)
        elif line == "else":
            conditions[-1] = not conditions[-1]
        elif line == "endif":
            conditions.pop()
        elif line.startswith(("ifeq", "ifneq", "else ")):
            raise ValueError(f"Unsupported conditional in {path}: {line}")
        elif all(conditions):
            yield line
    if conditions:
        raise ValueError(f"Unterminated conditional in {path}")


def parse_makefile(path: Path) -> dict[str, list[str]]:
    """Parse OBJS, STLIBOBJS, and SHLIBOBJS component selections.

    Returns dict mapping config_name (lowercase) -> list of .o basenames
    (with subdirectory prefix if present).
    """
    mapping: dict[str, list[str]] = defaultdict(list)
    for line in _makefile_lines(path):
        match = re.match(
            r"(?:(\w+)-)?(?:OBJS|STLIBOBJS|SHLIBOBJS)-\$\(CONFIG_(\w+)\)\s*\+=\s*(.*)",
            line,
        )
        if match and match.group(1) in OBJECT_PREFIXES:
            config = match.group(2).lower()
            if config == "unstable":
                continue
            objs = re.findall(r"([\w./-]+\.o)\b", match.group(3))
            mapping[config].extend(objs)

    return dict(mapping)


def parse_unconditional_objs(path: Path, variable: str = "OBJS") -> set[str]:
    """Parse unconditional OBJS or SHLIBOBJS assignments from a Makefile.

    Returns a set of .o basenames that are always compiled.
    """
    objs: set[str] = set()
    for line in _makefile_lines(path):
        if re.match(rf"^{re.escape(variable)}\s*[+:]?=", line) and "CONFIG_" not in line:
            objs.update(re.findall(r"([\w./-]+\.o)\b", line.split("=", 1)[1]))

    return objs


# -- Source helpers -----------------------------------------------------------


def obj_to_src(ffmpeg_root: Path, lib_dir: str, obj_path: str) -> str | None:
    """Convert a .o path to its C, GNU assembly, or NASM source, if present."""
    stem = obj_path.rsplit(".o", 1)[0]
    for ext in (".c", ".S", ".asm"):
        if (ffmpeg_root / lib_dir / (stem + ext)).exists():
            return lib_dir + "/" + stem + ext
    return None


def is_arch_path(obj_path: str) -> bool:
    """True if the object file is under an architecture-specific directory."""
    parts = obj_path.split("/")
    return len(parts) > 1 and parts[0] in ARCH_DIRS


def should_skip_file(stem: str) -> bool:
    """True if this source file should be excluded (needs external deps)."""
    base = stem.rsplit("/", 1)[-1]
    return base in EXTERNAL_FILES_TO_SKIP


# -- Library processing (split into sub-functions) ----------------------------


def _collect_generic_mapping(
    ffmpeg_root: Path,
    lib_info: LibInfo,
    unconditional: set[str],
) -> dict[str, list[str]]:
    """Build the generic (non-arch) config -> object-file mapping."""
    lib_dir = lib_info.dir
    mapping: dict[str, list[str]] = defaultdict(list)

    main_objs = parse_makefile(ffmpeg_root / lib_dir / "Makefile")
    for config, objs in main_objs.items():
        for obj in objs:
            if not is_arch_path(obj) and obj not in unconditional:
                mapping[config].append(obj)

    for sub in lib_info.sub_makefiles:
        sub_mf = ffmpeg_root / lib_dir / sub / "Makefile"
        if not sub_mf.exists():
            continue
        for config, objs in parse_makefile(sub_mf).items():
            for obj in objs:
                if is_arch_path(obj):
                    continue
                # Included Makefiles already use paths relative to lib_dir.
                if obj not in unconditional:
                    mapping[config].append(obj)

    return dict(mapping)


def _collect_arch_srcs(
    ffmpeg_root: Path,
    lib_dir: str,
    arch: str,
) -> dict[str, set[str]]:
    """Read architecture and matching intrinsics Makefile selections."""
    mapping: dict[str, list[str]] = defaultdict(list)
    directories = [arch, "neon"] if arch == "aarch64" else [arch]
    for directory in directories:
        for mf_path in sorted((ffmpeg_root / lib_dir / directory).rglob("Makefile")):
            for config, objs in parse_makefile(mf_path).items():
                mapping[config].extend(objs)
    return _classify_objects(ffmpeg_root, lib_dir, mapping)


class SourceGroups(NamedTuple):
    """Sources grouped by the component flags that require them."""

    exclusive: dict[str, list[str]]
    shared: list[tuple[list[str], list[str]]]


class LibrarySources(NamedTuple):
    """Categorised source files produced by process_library."""

    unconditional: list[str]
    components: SourceGroups
    extra: SourceGroups
    aarch64: SourceGroups
    x86: SourceGroups
    x86_asm: SourceGroups


def _classify_objects(
    ffmpeg_root: Path,
    lib_dir: str,
    generic_mapping: dict[str, list[str]],
    config_names: set[str] | None = None,
) -> dict[str, set[str]]:
    """Associate source files with every component or subsystem using them.

    A source file may appear under both CONFIG_EXTRA_REGISTRY and
    PROFILE_EVERYTHING (e.g. h2645_parse.c is used by both h264parse and
    extract_extradata_bsf). Retain both associations so either flag selects it.
    """
    component_file_map: dict[str, set[str]] = defaultdict(set)
    if config_names is None:
        config_names = CONFIG_EXTRA_SET | PROFILE_EVERYTHING_SET

    for config, objs in generic_mapping.items():
        if config not in config_names:
            continue
        for obj in objs:
            stem = obj.rsplit(".o", 1)[0]
            if should_skip_file(stem):
                continue
            src = obj_to_src(ffmpeg_root, lib_dir, obj)
            if src is None or src in MANUAL_SRCS:
                continue
            component_file_map[config].add(src)

    return component_file_map


def _categorize_sources(
    component_file_map: dict[str, set[str]],
) -> SourceGroups:
    """Assign every source to exactly one exclusive or shared group."""
    file_to_components: dict[str, set[str]] = defaultdict(set)
    for comp, srcs in component_file_map.items():
        for src in srcs:
            file_to_components[src].add(comp)

    exclusive: dict[str, list[str]] = defaultdict(list)
    shared_groups: dict[frozenset[str], list[str]] = defaultdict(list)

    for src, comps in file_to_components.items():
        key = frozenset(comps)
        if len(key) == 1:
            exclusive[next(iter(key))].append(src)
        else:
            shared_groups[key].append(src)

    sorted_exclusive = {k: sorted(v) for k, v in sorted(exclusive.items())}
    sorted_shared: list[tuple[list[str], list[str]]] = [
        (sorted(comps), sorted(files))
        for comps, files in sorted(
            shared_groups.items(),
            key=lambda x: sorted(x[0]),
        )
    ]
    return SourceGroups(sorted_exclusive, sorted_shared)


def _split_extra_sources(groups: SourceGroups) -> tuple[SourceGroups, SourceGroups]:
    """Separate subsystem groups without duplicating mixed component groups."""
    components = SourceGroups({}, [])
    extra = SourceGroups({}, [])
    for comp, files in groups.exclusive.items():
        target = extra if comp in CONFIG_EXTRA_SET else components
        target.exclusive[comp] = files
    for comps, files in groups.shared:
        target = extra if CONFIG_EXTRA_SET.intersection(comps) else components
        target.shared.append((comps, files))
    return components, extra


def process_library(ffmpeg_root: Path, lib_info: LibInfo) -> LibrarySources:
    """Process one library and return its source-file groups."""
    lib_dir = lib_info.dir
    unconditional = parse_unconditional_objs(ffmpeg_root / lib_dir / "Makefile")

    generic_mapping = _collect_generic_mapping(
        ffmpeg_root,
        lib_info,
        unconditional,
    )
    fixed_mapping = _classify_objects(ffmpeg_root, lib_dir, generic_mapping, STATIC_CONFIG_SET)
    fixed_sources = {src for files in fixed_mapping.values() for src in files}
    # cc_library produces both static and shared libraries. Keep the SHLIBOBJS
    # copies of hidden symbols in each library, as ffbuild/library.mak does.
    shared_objs = parse_unconditional_objs(ffmpeg_root / lib_dir / "Makefile", "SHLIBOBJS")
    for obj in shared_objs - unconditional:
        src = obj_to_src(ffmpeg_root, lib_dir, obj)
        if src is not None:
            fixed_sources.add(src)
    component_mapping = _classify_objects(ffmpeg_root, lib_dir, generic_mapping)
    components, extra = _split_extra_sources(
        _categorize_sources({comp: files - fixed_sources for comp, files in component_mapping.items()}),
    )
    x86 = _collect_arch_srcs(ffmpeg_root, lib_dir, "x86")

    return LibrarySources(
        unconditional=sorted(fixed_sources),
        components=components,
        extra=extra,
        aarch64=_categorize_sources(_collect_arch_srcs(ffmpeg_root, lib_dir, "aarch64")),
        x86=_categorize_sources({c: {s for s in files if not s.endswith(".asm")} for c, files in x86.items()}),
        x86_asm=_categorize_sources({c: {s for s in files if s.endswith(".asm")} for c, files in x86.items()}),
    )


# -- Starlark formatting ------------------------------------------------------


def fmt_list(items: list[str], indent: int = 4) -> str:
    """Format a Python list as a Starlark list literal."""
    if not items:
        return "[]"
    pad = " " * indent
    lines = ["["]
    for item in items:
        lines.append(f'{pad}"{item}",')
    lines.append(" " * (indent - 4) + "]")
    return "\n".join(lines)


def fmt_string_list(items: list[str], indent: int = 8) -> str:
    """Format a list of strings for embedding inside a dict."""
    if not items:
        return "[]"
    if len(items) == 1:
        return f'["{items[0]}"]'
    pad = " " * indent
    lines = ["["]
    for item in items:
        lines.append(f'{pad}"{item}",')
    lines.append(" " * (indent - 4) + "]")
    return "\n".join(lines)


def _emit_groups_to(
    name: str,
    data: SourceGroups,
    all_shared_groups: set[tuple[str, ...]],
    emit,
) -> None:
    """Emit component selections and register every shared-source group."""
    emit(f"{name}_EXCLUSIVE_SRCS = {{")
    for comp, srcs in sorted(data.exclusive.items()):
        emit(f'    "{comp}": {fmt_string_list(srcs)},')
    emit("}")
    emit()

    emit(f"{name}_SHARED_SRCS = [")
    for comps, files in data.shared:
        all_shared_groups.add(tuple(comps))
        comps_str = ", ".join(f'"{c}"' for c in comps)
        files_str = ", ".join(f'"{f}"' for f in files)
        emit(f"    (({comps_str}), [{files_str}]),")
    emit("]")
    emit()


def _emit_library_to(
    lib_info: LibInfo,
    ffmpeg_root: Path,
    all_shared_groups: set[tuple[str, ...]],
    emit,
) -> None:
    """Emit generic, subsystem, and architecture selections for one library."""
    name = lib_info.name.upper()
    data = process_library(ffmpeg_root, lib_info)

    # Fixed CONFIG_* values can require sources even without any component flag,
    # such as libavcodec's STLIBOBJS-$(CONFIG_AVFORMAT) dependencies.
    emit(f"{name}_EXTRA_SRCS = {fmt_list(data.unconditional)}")
    emit()
    _emit_groups_to(name + "_EXTRA", data.extra, all_shared_groups, emit)
    _emit_groups_to(name, data.components, all_shared_groups, emit)

    for arch, groups in [("AARCH64", data.aarch64), ("X86", data.x86)]:
        emit(f"{name}_{arch}_COMPONENT_SRCS = []")
        emit()
        _emit_groups_to(name + "_" + arch, groups, all_shared_groups, emit)
    _emit_groups_to(name + "_X86_ASM", data.x86_asm, all_shared_groups, emit)
    if lib_info.name == "avcodec":
        _emit_asm_directories_to(name + "_X86_ASM", data.x86_asm, emit)


def _emit_asm_directories_to(name: str, groups: SourceGroups, emit) -> None:
    """Partition NASM targets to avoid rules_nasm's basename object collisions."""
    by_dir: dict[str, SourceGroups] = {}
    for comp, files in groups.exclusive.items():
        for src in files:
            directory = src.rsplit("/", 1)[0]
            group = by_dir.setdefault(directory, SourceGroups({}, []))
            group.exclusive.setdefault(comp, []).append(src)
    for comps, files in groups.shared:
        files_by_dir: dict[str, list[str]] = defaultdict(list)
        for src in files:
            files_by_dir[src.rsplit("/", 1)[0]].append(src)
        for directory, directory_files in sorted(files_by_dir.items()):
            group = by_dir.setdefault(directory, SourceGroups({}, []))
            group.shared.append((comps, directory_files))

    emit(f"{name}_EXCLUSIVE_SRCS_BY_DIR = {{")
    for directory, group in sorted(by_dir.items()):
        emit(f'    "{directory}": {{')
        for comp, files in group.exclusive.items():
            emit(f'        "{comp}": {fmt_string_list(files, indent=12)},')
        emit("    },")
    emit("}")
    emit()
    emit(f"{name}_SHARED_SRCS_BY_DIR = {{")
    for directory, group in sorted(by_dir.items()):
        emit(f'    "{directory}": [')
        for comps, files in group.shared:
            comps_str = ", ".join(f'"{c}"' for c in comps)
            files_str = ", ".join(f'"{src}"' for src in files)
            emit(f"        (({comps_str}), [{files_str}]),")
        emit("    ],")
    emit("}")
    emit()


def shared_group_definitions(
    reference_path: Path,
    groups: set[tuple[str, ...]],
) -> tuple[dict[str, list[tuple[str, list[str]]]], list[str]]:
    """Retain component_srcs.bzl IDs, aliases, and sections for surviving groups."""
    sections: dict[str, list[tuple[str, list[str]]]] = {}
    section_order: list[str] = []
    reserved_ids: set[str] = set()
    reference_groups: set[tuple[str, ...]] = set()
    groups = {tuple(sorted(comps)) for comps in groups}

    def section_names(value: ast.expr) -> list[str]:
        if isinstance(value, ast.Name):
            return [value.id]
        if isinstance(value, ast.BinOp) and isinstance(value.op, ast.Add):
            return section_names(value.left) + section_names(value.right)
        raise ValueError(f"Unsupported shared-group section expression in {reference_path}")

    for node in ast.parse(reference_path.read_text(encoding="utf-8")).body:
        if not isinstance(node, ast.Assign) or not isinstance(node.targets[0], ast.Name):
            continue
        name = node.targets[0].id
        if name == "ALL_SHARED_GROUP_DEFINITIONS":
            section_order = section_names(node.value)
        elif name.endswith("SHARED_GROUP_DEFINITIONS") and isinstance(node.value, ast.List):
            sections[name] = []
            for gid, comps in ast.literal_eval(node.value):
                if gid in reserved_ids:
                    raise ValueError(f"Duplicate shared-group ID {gid} in {reference_path}")
                reserved_ids.add(gid)
                key = tuple(sorted(comps))
                reference_groups.add(key)
                if key in groups:
                    # Historical aliases have distinct IDs; retain all surviving
                    # aliases and their original section and concatenation order.
                    sections[name].append((gid, list(key)))

    if not sections:
        raise ValueError(f"No shared-group definitions found in {reference_path}")
    if not section_order:
        section_order = list(sections)
    if set(section_order) != set(sections) or len(section_order) != len(sections):
        raise ValueError(f"Invalid ALL_SHARED_GROUP_DEFINITIONS in {reference_path}")
    if "SHARED_GROUP_DEFINITIONS" not in sections:
        sections["SHARED_GROUP_DEFINITIONS"] = []
        section_order.append("SHARED_GROUP_DEFINITIONS")

    next_id = max(
        (int(match.group(1)) for gid in reserved_ids if (match := re.fullmatch(r"shared_group_(\d+)", gid))),
        default=0,
    )
    for comps in sorted(groups - reference_groups):
        next_id += 1
        sections["SHARED_GROUP_DEFINITIONS"].append((f"shared_group_{next_id}", list(comps)))
    return sections, section_order


def _emit_shared_group_definitions_to(name: str, groups: list[tuple[str, list[str]]], emit) -> None:
    emit(f"{name} = [")
    for gid, comps in groups:
        comps_str = ", ".join(f'"{c}"' for c in comps)
        emit(f'    ("{gid}", [{comps_str}]),')
    emit("]")
    emit()


# -- Entry point --------------------------------------------------------------


def main() -> None:
    """Parse FFmpeg Makefiles and write component_srcs.bzl to the overlay."""
    global PROFILE_EVERYTHING_SET, CONFIG_EXTRA_SET, STATIC_CONFIG_SET

    parser = argparse.ArgumentParser(
        description="Generate component_srcs.bzl from FFmpeg Makefiles.",
    )
    parser.add_argument(
        "ffmpeg_source_root",
        type=Path,
        help="Path to the FFmpeg source tree",
    )
    add_version_arg(parser)
    parser.add_argument(
        "--reference-version",
        default="7.1.1.bcr.beta.7",
        help="Immutable module version supplying shared-group IDs and section order.",
    )
    args = parser.parse_args()

    overlay = resolve_overlay_dir(args.version)
    reference_overlay = resolve_overlay_dir(args.reference_version)
    if overlay.resolve() == reference_overlay.resolve():
        parser.error("--reference-version must name a different immutable overlay")
    PROFILE_EVERYTHING_SET = load_profile_everything(overlay / "component_defs.bzl")
    CONFIG_EXTRA_SET = load_registry_keys(overlay / "component_defs.bzl", "CONFIG_EXTRA_REGISTRY")
    STATIC_CONFIG_SET = load_static_configs(overlay / "config.h.in")
    ffmpeg_root: Path = args.ffmpeg_source_root

    output_path = overlay / "component_srcs.bzl"
    buf: list[str] = []

    def emit(line: str = "") -> None:
        buf.append(line)

    emit('"""Auto-generated FFmpeg per-component source file mappings.')
    emit("")
    emit("Generated by generate_component_srcs.py from FFmpeg Makefiles.")
    emit("Do not edit manually.")
    emit('"""')
    emit()

    all_shared_groups: set[tuple[str, ...]] = set()
    library_output: dict[str, list[str]] = {}
    for lib_info in LIBS:
        lines: list[str] = []
        _emit_library_to(lib_info, ffmpeg_root, all_shared_groups, lambda line="", lines=lines: lines.append(line))
        library_output[lib_info.name] = lines

    sections, section_order = shared_group_definitions(
        reference_overlay / "component_srcs.bzl",
        all_shared_groups,
    )
    library_sections = {
        "avcodec": "X86_SHARED_GROUP_DEFINITIONS",
        "avfilter": "AVFILTER_X86_SHARED_GROUP_DEFINITIONS",
    }
    for name, lines in library_output.items():
        buf.extend(lines)
        section = library_sections.get(name)
        if section in sections:
            _emit_shared_group_definitions_to(section, sections.pop(section), emit)
    for name, groups in sections.items():
        _emit_shared_group_definitions_to(name, groups, emit)
    emit("ALL_SHARED_GROUP_DEFINITIONS = " + " + ".join(section_order))

    output_path.write_text("\n".join(buf) + "\n", encoding="utf-8")
    print(f"  wrote {output_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
