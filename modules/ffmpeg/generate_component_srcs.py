#!/usr/bin/env python3
"""Parse FFmpeg Makefiles and generate component_srcs.bzl.

Extracts OBJS-$(CONFIG_*) mappings from each library's Makefile (and its
sub-Makefiles) to produce a Starlark file with per-library source-file
dictionaries consumed by the Bazel build.

Usage:
    python3 generate_component_srcs.py <ffmpeg_source_root> > component_srcs.bzl

The script reads PROFILE_EVERYTHING from component_defs.bzl (in the same
directory as this script) to determine which CONFIG_ entries correspond to
actual FFmpeg components vs. internal subsystems or platform flags.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import NamedTuple

CONFIG_EXTRA: list[str] = [
    "aandcttables",
    "ac3dsp",
    "adts_header",
    "atsc_a53",
    "audio_frame_queue",
    "audiodsp",
    "blockdsp",
    "bswapdsp",
    "cabac",
    "cbs",
    "cbs_av1",
    "cbs_h264",
    "cbs_h265",
    "cbs_h266",
    "cbs_jpeg",
    "cbs_mpeg2",
    "cbs_vp8",
    "cbs_vp9",
    "d3d12va_encode",
    "deflate_wrapper",
    "dirac_parse",
    "dnn",
    "dovi_rpudec",
    "dovi_rpuenc",
    "dvprofile",
    "evcparse",
    "exif",
    "faandct",
    "faanidct",
    "fdctdsp",
    "fmtconvert",
    "frame_thread_encoder",
    "g722dsp",
    "golomb",
    "gplv3",
    "h263dsp",
    "h264chroma",
    "h264dsp",
    "h264parse",
    "h264pred",
    "h264qpel",
    "h264_sei",
    "hevcparse",
    "hevc_sei",
    "hpeldsp",
    "huffman",
    "huffyuvdsp",
    "huffyuvencdsp",
    "iamfdec",
    "iamfenc",
    "idctdsp",
    "iirfilter",
    "inflate_wrapper",
    "intrax8",
    "iso_media",
    "iso_writer",
    "ividsp",
    "jpegtables",
    "lgplv3",
    "libx262",
    "libx264_hdr10",
    "llauddsp",
    "llviddsp",
    "llvidencdsp",
    "lpc",
    "lzf",
    "me_cmp",
    "mpeg_er",
    "mpegaudio",
    "mpegaudiodsp",
    "mpegaudioheader",
    "mpeg4audio",
    "mpegvideo",
    "mpegvideodec",
    "mpegvideoenc",
    "msmpeg4dec",
    "msmpeg4enc",
    "mss34dsp",
    "pixblockdsp",
    "qpeldsp",
    "qsv",
    "qsvdec",
    "qsvenc",
    "qsvvpp",
    "rangecoder",
    "riffdec",
    "riffenc",
    "rtpdec",
    "rtpenc_chain",
    "rv34dsp",
    "scene_sad",
    "sinewin",
    "snappy",
    "srtp",
    "startcode",
    "texturedsp",
    "texturedspenc",
    "tpeldsp",
    "vaapi_1",
    "vaapi_encode",
    "vc1dsp",
    "videodsp",
    "vp3dsp",
    "vp56dsp",
    "vp8dsp",
    "vulkan_encode",
    "wma_freqs",
    "wmv2dsp",
]
CONFIG_EXTRA_SET: set[str] = set(CONFIG_EXTRA)

ARCH_DIRS: set[str] = {
    "x86",
    "aarch64",
    "arm",
    "ppc",
    "mips",
    "loongarch",
    "riscv",
    "neon",
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


def load_profile_everything() -> set[str]:
    """Parse PROFILE_EVERYTHING from component_defs.bzl in the same directory."""
    defs_path = Path(__file__).parent / "component_defs.bzl"
    content = defs_path.read_text(encoding="utf-8")
    match = re.search(
        r"PROFILE_EVERYTHING\s*=\s*\[(.*?)\]",
        content,
        re.DOTALL,
    )
    if not match:
        print(
            "ERROR: Could not find PROFILE_EVERYTHING in component_defs.bzl",
            file=sys.stderr,
        )
        sys.exit(1)
    return set(re.findall(r'"([^"]+)"', match.group(1)))


PROFILE_EVERYTHING_SET: set[str] = load_profile_everything()


# -- Makefile parsing ---------------------------------------------------------


def parse_makefile(path: Path) -> dict[str, list[str]]:
    """Parse OBJS-$(CONFIG_*) lines from a Makefile, handling continuations.

    Returns dict mapping config_name (lowercase) -> list of .o basenames
    (with subdirectory prefix if present).
    """
    mapping: dict[str, list[str]] = defaultdict(list)
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)

    idx = 0
    while idx < len(lines):
        line = lines[idx].rstrip()
        match = re.match(
            r"(?:\w+-)?OBJS-\$\(CONFIG_(\w+)\)\s*\+=\s*(.*)",
            line,
        )
        if match:
            config = match.group(1).lower()
            objs_str = match.group(2)
            while objs_str.endswith("\\"):
                objs_str = objs_str[:-1]
                idx += 1
                if idx < len(lines):
                    objs_str += " " + lines[idx].strip()
            objs = re.findall(r"(\S+\.o)", objs_str)
            mapping[config].extend(objs)
        idx += 1

    return dict(mapping)


def parse_unconditional_objs(path: Path) -> set[str]:
    """Parse unconditional OBJS from a Makefile (OBJS = / OBJS +=, no CONFIG_).

    Returns a set of .o basenames that are always compiled.
    """
    objs: set[str] = set()
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)

    idx = 0
    while idx < len(lines):
        line = lines[idx].rstrip()
        if re.match(r"^OBJS\s*[+:]?=", line) and "CONFIG_" not in line:
            parts = line.split("=", 1)[1]
            while True:
                for obj_match in re.finditer(r"(\S+\.o)", parts):
                    objs.add(obj_match.group(1))
                if "\\" in line:
                    idx += 1
                    if idx < len(lines):
                        line = lines[idx].rstrip()
                        parts = line
                    else:
                        break
                else:
                    break
        idx += 1

    return objs


# -- Source helpers -----------------------------------------------------------


def obj_to_src(ffmpeg_root: Path, lib_dir: str, obj_path: str) -> str | None:
    """Convert a .o path to its .c or .S source path, or None if missing."""
    stem = obj_path.rsplit(".o", 1)[0]
    for ext in (".c", ".S"):
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
                prefixed = sub + "/" + obj
                if prefixed not in unconditional and obj not in unconditional:
                    mapping[config].append(obj)

    return dict(mapping)


def _collect_arch_srcs(
    ffmpeg_root: Path,
    lib_dir: str,
    arch: str,
) -> list[str]:
    """Resolve arch-specific Makefile objects into sorted source paths."""
    mf_path = ffmpeg_root / lib_dir / arch / "Makefile"
    if not mf_path.exists():
        return []

    srcs: set[str] = set()
    for objs in parse_makefile(mf_path).values():
        for obj in objs:
            src = obj_to_src(ffmpeg_root, lib_dir, obj)
            if src is not None:
                srcs.add(src)
    return sorted(srcs)


class LibrarySources(NamedTuple):
    """Categorised source files produced by process_library."""

    extra: list[str]
    exclusive: dict[str, list[str]]
    shared: list[tuple[list[str], list[str]]]
    aarch64: list[str]
    x86: list[str]


def _classify_objects(
    ffmpeg_root: Path,
    lib_dir: str,
    generic_mapping: dict[str, list[str]],
) -> tuple[set[str], dict[str, set[str]]]:
    """Classify object files into extra infrastructure and component sources."""
    extra_srcs: set[str] = set()
    component_file_map: dict[str, set[str]] = defaultdict(set)

    for config, objs in generic_mapping.items():
        for obj in objs:
            stem = obj.rsplit(".o", 1)[0]
            if should_skip_file(stem):
                continue
            src = obj_to_src(ffmpeg_root, lib_dir, obj)
            if src is None:
                continue
            if config in CONFIG_EXTRA_SET:
                extra_srcs.add(src)
            elif config in PROFILE_EVERYTHING_SET:
                component_file_map[config].add(src)

    return extra_srcs, component_file_map


def _categorize_sources(
    ffmpeg_root: Path,
    lib_dir: str,
    generic_mapping: dict[str, list[str]],
) -> tuple[list[str], dict[str, list[str]], list[tuple[list[str], list[str]]]]:
    """Split generic mapping into extra, exclusive, and shared source groups."""
    extra_srcs, component_file_map = _classify_objects(
        ffmpeg_root,
        lib_dir,
        generic_mapping,
    )

    file_to_components: dict[str, set[str]] = defaultdict(set)
    for comp, srcs in component_file_map.items():
        for src in srcs:
            file_to_components[src].add(comp)

    exclusive: dict[str, list[str]] = defaultdict(list)
    shared_groups: dict[frozenset[str], list[str]] = defaultdict(list)

    for src, comps in file_to_components.items():
        if src in extra_srcs:
            continue
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
    return sorted(extra_srcs), sorted_exclusive, sorted_shared


def process_library(ffmpeg_root: Path, lib_info: LibInfo) -> LibrarySources:
    """Process one library and return its source-file groups."""
    lib_dir = lib_info.dir
    unconditional = parse_unconditional_objs(ffmpeg_root / lib_dir / "Makefile")

    generic_mapping = _collect_generic_mapping(
        ffmpeg_root,
        lib_info,
        unconditional,
    )
    extra, exclusive, shared = _categorize_sources(
        ffmpeg_root,
        lib_dir,
        generic_mapping,
    )

    return LibrarySources(
        extra=extra,
        exclusive=exclusive,
        shared=shared,
        aarch64=_collect_arch_srcs(ffmpeg_root, lib_dir, "aarch64"),
        x86=_collect_arch_srcs(ffmpeg_root, lib_dir, "x86"),
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


def _emit_library(
    lib_info: LibInfo,
    ffmpeg_root: Path,
    all_shared_groups: dict[tuple[str, ...], str],
    group_counter: list[int],
) -> None:
    """Process and print Starlark output for a single FFmpeg library."""
    name = lib_info.name.upper()
    data = process_library(ffmpeg_root, lib_info)

    print(f"{name}_EXTRA_SRCS = {fmt_list(data.extra)}")
    print()

    print(f"{name}_EXCLUSIVE_SRCS = {{")
    for comp, srcs in sorted(data.exclusive.items()):
        print(f'    "{comp}": {fmt_string_list(srcs)},')
    print("}")
    print()

    shared_var_entries: list[tuple[str, list[str], list[str]]] = []
    for comps, files in data.shared:
        group_key = tuple(comps)
        if group_key not in all_shared_groups:
            group_counter[0] += 1
            all_shared_groups[group_key] = f"shared_group_{group_counter[0]}"
        shared_var_entries.append(
            (all_shared_groups[group_key], comps, files),
        )

    print(f"{name}_SHARED_SRCS = [")
    for _gid, comps, files in shared_var_entries:
        comps_str = ", ".join(f'"{c}"' for c in comps)
        files_str = ", ".join(f'"{f}"' for f in files)
        print(f"    (({comps_str}), [{files_str}]),")
    print("]")
    print()

    if data.aarch64:
        print(
            f"{name}_AARCH64_COMPONENT_SRCS = {fmt_list(data.aarch64)}",
        )
        print()

    if data.x86:
        print(f"{name}_X86_COMPONENT_SRCS = {fmt_list(data.x86)}")
        print()


# -- Entry point --------------------------------------------------------------


def main() -> None:
    """Parse FFmpeg Makefiles and emit component_srcs.bzl to stdout."""
    parser = argparse.ArgumentParser(
        description="Generate component_srcs.bzl from FFmpeg Makefiles.",
    )
    parser.add_argument(
        "ffmpeg_source_root",
        type=Path,
        help="Path to the FFmpeg source tree",
    )
    args = parser.parse_args()

    ffmpeg_root: Path = args.ffmpeg_source_root

    print('"""Auto-generated FFmpeg per-component source file mappings.')
    print("")
    print("Generated by generate_component_srcs.py from FFmpeg Makefiles.")
    print("Do not edit manually.")
    print('"""')
    print()

    all_shared_groups: dict[tuple[str, ...], str] = {}
    group_counter = [0]

    for lib_info in LIBS:
        _emit_library(lib_info, ffmpeg_root, all_shared_groups, group_counter)

    print("SHARED_GROUP_DEFINITIONS = [")
    for group_key, gid in sorted(
        all_shared_groups.items(),
        key=lambda x: x[1],
    ):
        comps_str = ", ".join(f'"{c}"' for c in group_key)
        print(f'    ("{gid}", [{comps_str}]),')
    print("]")


if __name__ == "__main__":
    main()
