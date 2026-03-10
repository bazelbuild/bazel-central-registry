#!/usr/bin/env python3
"""Generate config_defs.bzl by parsing FFmpeg's configure script.

Extracts ARCH_LIST, HAVE_LIST, CONFIG_LIST, CONFIG_EXTRA, HAVE_LIST_PUB,
and COMPONENT_LIST from the configure script, then emits a Starlark file
with AVCONFIG_H, FFVERSION_H, and CONFIG_H_IN constants.

Usage:
    python3 generate_config_defs.py /path/to/FFmpeg > config_defs.bzl
    python3 generate_config_defs.py /path/to/FFmpeg --version 7.2
"""

import argparse
import os
import re
import sys
from collections import OrderedDict


# ---------------------------------------------------------------------------
# Build-policy defaults: CONFIG_* flags set to 1 in the Bazel build.
# Everything not listed here defaults to 0.
# ---------------------------------------------------------------------------

CONFIG_ENABLED = {
    # Libraries
    "avcodec",
    "avdevice",
    "avfilter",
    "avformat",
    "avutil",
    "swresample",
    "swscale",
    # Programs
    "ffmpeg",
    "ffprobe",
    # Component categories
    "filters",
    # Subsystems
    "faan",
    "fast_unaligned",
    "iamf",
    "network",
    # Features
    "runtime_cpudetect",
    "safe_bitstream_reader",
    "static",
    "swscale_alpha",
    # Build flags
    "large_tests",
    "pic",
    "ptx_compression",
    # Documents
    "manpages",
    "podpages",
    # External autodetect libs available in Bazel
    "bzlib",
    "zlib",
    # Examples (enabled by default)
    "avio_http_serve_files_example",
    "avio_list_dir_example",
    "avio_read_callback_example",
    "decode_audio_example",
    "decode_filter_audio_example",
    "decode_filter_video_example",
    "decode_video_example",
    "demux_decode_example",
    "encode_audio_example",
    "encode_video_example",
    "extract_mvs_example",
    "filter_audio_example",
    "hw_decode_example",
    "mux_example",
    "remux_example",
    "resample_audio_example",
    "scale_video_example",
    "show_metadata_example",
    "transcode_aac_example",
    "transcode_example",
}

# Standard C99/POSIX math functions checked via AC_CHECK_LIB in the Bazel
# build (mirroring FFmpeg's check_mathfunc in configure). These are available
# on all supported platforms, so their #ifndef fallback defaults to 1 instead
# of 0. This ensures a working build even if the autoconf probe fails (e.g.
# due to ABI mismatches in the default AC_CHECK_LIB template on ARM64).
HAVE_MATH_FUNCS_DEFAULT_1 = frozenset(
    {
        "atanf",
        "atan2f",
        "cbrt",
        "cbrtf",
        "copysign",
        "cosf",
        "erf",
        "exp2",
        "exp2f",
        "expf",
        "hypot",
        "isfinite",
        "isinf",
        "isnan",
        "ldexpf",
        "llrint",
        "llrintf",
        "log2",
        "log2f",
        "log10f",
        "lrint",
        "lrintf",
        "powf",
        "rint",
        "round",
        "roundf",
        "sinf",
        "trunc",
        "truncf",
    }
)

# CONFIG_* flags detected via autoconf at build time (emitted as #undef
# in the template, with #ifndef fallbacks). These are a subset of
# EXTERNAL_AUTODETECT_LIBRARY_LIST items that can be detected by
# compile-time checks rather than pkg-config.
AUTOCONF_DETECTED_CONFIGS = {
    "appkit",
    "audiotoolbox",
    "avfoundation",
    "coreimage",
    "iconv",
    "securetransport",
    "videotoolbox",
}


# ---------------------------------------------------------------------------
# Configure script parser
# ---------------------------------------------------------------------------


def parse_configure(configure_path: str) -> dict[str, str]:
    """Extract all VARNAME="..." shell variable assignments."""
    with open(configure_path) as f:
        text = f.read()

    variables: dict[str, str] = OrderedDict()
    pattern = re.compile(
        r'^([A-Z][A-Z0-9_]*)="(.*?)"',
        re.MULTILINE | re.DOTALL,
    )
    for m in pattern.finditer(text):
        name = m.group(1)
        body = m.group(2)
        variables[name] = body

    return variables


def resolve_list(
    var_name: str,
    raw_vars: dict[str, str],
    cache: dict[str, list[str]] | None = None,
) -> list[str]:
    """Resolve a shell variable to a flat list of identifiers.

    Handles $VAR references and $(add_suffix SUFFIX $VAR) calls.
    """
    if cache is None:
        cache = {}
    if var_name in cache:
        return cache[var_name]

    body = raw_vars.get(var_name, "")
    items: list[str] = []

    for token in body.split():
        if token.startswith("$(add_suffix"):
            continue

        add_suffix_match = re.match(r"^\$\(add_suffix\s+(\S+)\s+\$(\S+)\)$", token)
        if add_suffix_match:
            suffix = add_suffix_match.group(1)
            ref = add_suffix_match.group(2)
            for item in resolve_list(ref, raw_vars, cache):
                items.append(item + suffix)
            continue

        if token.startswith("$"):
            ref = token.lstrip("$").strip("{}")
            items.extend(resolve_list(ref, raw_vars, cache))
            continue

        if re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", token):
            items.append(token)

    cache[var_name] = items
    return items


def resolve_have_list(raw_vars: dict[str, str], cache: dict[str, list[str]]) -> list[str]:
    """Resolve HAVE_LIST with special handling for $(add_suffix) in its body."""
    body = raw_vars.get("HAVE_LIST", "")
    items: list[str] = []

    i = 0
    tokens = body.split()
    while i < len(tokens):
        token = tokens[i]

        if token == "$(add_suffix" and i + 2 < len(tokens):
            suffix_tok = tokens[i + 1]
            ref_tok = tokens[i + 2].rstrip(")")
            ref = ref_tok.lstrip("$").strip("{}")
            for item in resolve_list(ref, raw_vars, cache):
                items.append(item + suffix_tok)
            i += 3
            continue

        if token.startswith("$"):
            ref = token.lstrip("$").strip("{}")
            items.extend(resolve_list(ref, raw_vars, cache))
            i += 1
            continue

        if re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", token):
            items.append(token)
        i += 1

    return items


def dedup(items: list[str]) -> list[str]:
    """Remove duplicates while preserving order."""
    seen: set[str] = set()
    result: list[str] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result


def extract_all_lists(configure_path: str) -> dict[str, list[str]]:
    """Parse configure and return all resolved variable lists."""
    raw_vars = parse_configure(configure_path)
    cache: dict[str, list[str]] = {}

    result = {}
    result["ARCH_LIST"] = dedup(resolve_list("ARCH_LIST", raw_vars, cache))
    result["HAVE_LIST"] = dedup(resolve_have_list(raw_vars, cache))
    result["CONFIG_LIST"] = dedup(resolve_list("CONFIG_LIST", raw_vars, cache))
    result["CONFIG_EXTRA"] = dedup(resolve_list("CONFIG_EXTRA", raw_vars, cache))
    result["HAVE_LIST_PUB"] = dedup(resolve_list("HAVE_LIST_PUB", raw_vars, cache))
    result["COMPONENT_LIST"] = dedup(resolve_list("COMPONENT_LIST", raw_vars, cache))

    return result


# ---------------------------------------------------------------------------
# Version extraction
# ---------------------------------------------------------------------------


def extract_version(ffmpeg_root: str) -> str:
    """Read the FFmpeg version from the RELEASE file."""
    release_path = os.path.join(ffmpeg_root, "RELEASE")
    if os.path.isfile(release_path):
        with open(release_path) as f:
            return f.read().strip()
    raise FileNotFoundError(f"Cannot find {release_path}")


# ---------------------------------------------------------------------------
# Starlark output generation
# ---------------------------------------------------------------------------


def generate_avconfig_h(have_list_pub: list[str]) -> list[str]:
    """Generate AVCONFIG_H lines from HAVE_LIST_PUB."""
    defaults = {"bigendian": 0, "fast_unaligned": 1}
    lines = [
        "/* Generated by Bazel */",
        "#ifndef AVUTIL_AVCONFIG_H",
        "#define AVUTIL_AVCONFIG_H",
    ]
    for item in have_list_pub:
        val = defaults.get(item, 0)
        lines.append(f"#define AV_HAVE_{item.upper()} {val}")
    lines.append("#endif /* AVUTIL_AVCONFIG_H */")
    return lines


def generate_ffversion_h(version: str) -> list[str]:
    """Generate FFVERSION_H lines."""
    return [
        "/* Generated by Bazel */",
        "#ifndef AVUTIL_FFVERSION_H",
        "#define AVUTIL_FFVERSION_H",
        f'#define FFMPEG_VERSION "{version}"',
        "#endif /* AVUTIL_FFVERSION_H */",
    ]


def generate_config_h_in(
    arch_list: list[str],
    have_list: list[str],
    config_list: list[str],
) -> list[str]:
    """Generate CONFIG_H_IN lines."""
    lines: list[str] = []

    # --- Header guard and static metadata ---
    lines.extend(
        [
            "/* Automatically generated by Bazel - do not modify! */",
            "#ifndef FFMPEG_CONFIG_H",
            "#define FFMPEG_CONFIG_H",
            "",
            "/* --- Static metadata --- */",
            '#define FFMPEG_CONFIGURATION "bazel --disable-everything"',
            '#define FFMPEG_LICENSE "LGPL version 2.1 or later"',
            "#define CONFIG_THIS_YEAR 2025",
            '#define FFMPEG_DATADIR "/usr/local/share/ffmpeg"',
            '#define AVCONV_DATADIR "/usr/local/share/ffmpeg"',
            '#define CC_IDENT "bazel"',
            '#define BUILDSUF ""',
            "#define SWS_MAX_FILTER_SIZE 256",
            "",
            "/* --- OS metadata (substituted by autoconf_hdr) --- */",
            "#define OS_NAME @OS_NAME@",
            '#define EXTERN_PREFIX "@EXTERN_PREFIX@"',
            "#define EXTERN_ASM @EXTERN_ASM@",
            '#define SLIBSUF "@SLIBSUF@"',
        ]
    )

    # --- Architecture flags ---
    lines.append("")
    lines.append("/* --- Architecture flags (detected via autoconf) --- */")
    for arch in arch_list:
        lines.append(f"#undef ARCH_{arch.upper()}")

    # --- Conditional metadata ---
    lines.append("")
    lines.append("/* --- Conditional metadata (detected via autoconf) --- */")
    lines.append("#undef AS_ARCH_LEVEL")

    # --- HAVE_* feature detection ---
    lines.append("")
    lines.append("/* --- HAVE_* feature detection (detected via autoconf) --- */")
    for item in sorted(have_list, key=lambda x: x.upper()):
        lines.append(f"#undef HAVE_{item.upper()}")

    # --- Platform-detected CONFIG_* ---
    autoconf_configs = sorted(AUTOCONF_DETECTED_CONFIGS)
    lines.append("")
    lines.append("/* --- Platform-detected CONFIG_* (detected via autoconf) --- */")
    for item in autoconf_configs:
        lines.append(f"#undef CONFIG_{item.upper()}")

    # --- Build policy (empty section header) ---
    lines.append("")
    lines.append("/* --- Build policy CONFIG_* (static) --- */")

    # --- CONFIG_EXTRA subsystems ---
    lines.append("")
    lines.append("/* --- CONFIG_EXTRA subsystems (resolved by component selection) --- */")
    lines.append('#include "config_extra.h"')

    # --- Static CONFIG_* defines ---
    lines.append("")
    static_configs = sorted(
        (c for c in config_list if c not in AUTOCONF_DETECTED_CONFIGS),
        key=lambda x: x.upper(),
    )
    for item in static_configs:
        val = 1 if item in CONFIG_ENABLED else 0
        lines.append(f"#define CONFIG_{item.upper()} {val}")

    # --- Fallback defaults (all macros must be defined to 0 or 1) ---
    lines.append("")
    lines.append("// FFmpeg requires all detection macros defined to 0 or 1 (not undefined).")
    lines.append("// Provide defaults for any that were not set by autoconf checks above.")

    # ARCH_* fallbacks
    for arch in arch_list:
        name = f"ARCH_{arch.upper()}"
        lines.extend([f"#ifndef {name}", f"#define {name} 0", "#endif"])
    lines.extend(["#ifndef AS_ARCH_LEVEL", "#define AS_ARCH_LEVEL 0", "#endif"])

    # HAVE_* fallbacks — standard math functions default to 1 (universally
    # available on all supported platforms); everything else defaults to 0.
    for item in sorted(have_list, key=lambda x: x.upper()):
        name = f"HAVE_{item.upper()}"
        default = 1 if item.lower() in HAVE_MATH_FUNCS_DEFAULT_1 else 0
        lines.extend([f"#ifndef {name}", f"#define {name} {default}", "#endif"])

    # Autoconf-detected CONFIG_* fallbacks
    for item in autoconf_configs:
        name = f"CONFIG_{item.upper()}"
        lines.extend([f"#ifndef {name}", f"#define {name} 0", "#endif"])

    lines.append("")
    lines.append("#endif /* FFMPEG_CONFIG_H */")

    return lines


def format_starlark_list(name: str, items: list[str], indent: str = "    ") -> str:
    """Format a Starlark string-list constant."""
    parts = [f"{name} = ["]
    for item in items:
        escaped = item.replace("\\", "\\\\").replace('"', '\\"')
        parts.append(f'{indent}"{escaped}",')
    parts.append("]")
    return "\n".join(parts)


def main():
    parser = argparse.ArgumentParser(
        description="Generate config_defs.bzl from FFmpeg's configure script.",
    )
    parser.add_argument(
        "ffmpeg_root",
        help="Path to FFmpeg source tree root",
    )
    parser.add_argument(
        "--version",
        help="Override FFmpeg version string (default: read from RELEASE file)",
    )
    args = parser.parse_args()

    configure_path = os.path.join(args.ffmpeg_root, "configure")
    if not os.path.isfile(configure_path):
        print(f"Error: {configure_path} not found", file=sys.stderr)
        sys.exit(1)

    lists = extract_all_lists(configure_path)
    version = args.version or extract_version(args.ffmpeg_root)

    avconfig = generate_avconfig_h(lists["HAVE_LIST_PUB"])
    ffversion = generate_ffversion_h(version)
    config_h_in = generate_config_h_in(
        lists["ARCH_LIST"],
        lists["HAVE_LIST"],
        lists["CONFIG_LIST"],
    )

    parts = [
        '"""FFmpeg static configuration defines (avconfig.h, ffversion.h, config.h.in)."""',
        "",
        format_starlark_list("AVCONFIG_H", avconfig),
        "",
        format_starlark_list("FFVERSION_H", ffversion),
        "",
        format_starlark_list("CONFIG_H_IN", config_h_in),
        "",
    ]
    print("\n".join(parts), end="")


if __name__ == "__main__":
    main()
