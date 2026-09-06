#!/usr/bin/env python3
"""Generates overlay/config.in for an MPFR module from the MPFR source tree.

Parses configure.ac and acinclude.m4 to extract the superset of all symbols
that the autoconf build system may define, then writes a config.in template
with #undef directives for each.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_dir", type=Path, help="Path to MPFR source tree")
    parser.add_argument("--version", help="MPFR version (derived from source if omitted)")
    parser.add_argument(
        "--bcr-root",
        type=Path,
        default=Path(__file__).resolve().parent.parent.parent,
        help="Path to bazel-central-registry root",
    )
    return parser.parse_args()


def parse_version(source_dir: Path) -> str:
    version_file = source_dir / "VERSION"
    if version_file.exists():
        text = version_file.read_text().strip()
        return text.removesuffix("-dev")

    mpfr_h = source_dir / "src" / "mpfr.h"
    if not mpfr_h.exists():
        raise FileNotFoundError(f"Neither VERSION nor src/mpfr.h found in {source_dir}")
    text = mpfr_h.read_text()
    major = re.search(r"MPFR_VERSION_MAJOR\s+(\d+)", text)
    minor = re.search(r"MPFR_VERSION_MINOR\s+(\d+)", text)
    patch = re.search(r"MPFR_VERSION_PATCHLEVEL\s+(\d+)", text)
    if not all([major, minor, patch]):
        raise ValueError("Could not extract version from mpfr.h")
    return f"{major.group(1)}.{minor.group(1)}.{patch.group(1)}"


def _strip_m4_quotes(s: str) -> str:
    s = s.strip()
    if s.startswith("[") and s.endswith("]"):
        s = s[1:-1]
    return s.strip()


def _header_to_define(header: str) -> str:
    return "HAVE_" + header.upper().replace("/", "_").replace(".", "_")


def _func_to_define(func: str) -> str:
    return "HAVE_" + func.upper()


def _type_to_define(typename: str) -> str:
    return "HAVE_" + typename.upper().replace(" ", "_")


def _member_to_define(member: str) -> str:
    parts = member.strip().split(".")
    if len(parts) == 2:
        struct_part = parts[0].strip().upper().replace(" ", "_")
        field_part = parts[1].strip().upper()
        return f"HAVE_{struct_part}_{field_part}"
    return "HAVE_" + member.upper().replace(" ", "_").replace(".", "_")


def extract_defines(text: str) -> set[str]:
    """Extract all symbol names from AC_DEFINE and AC_DEFINE_UNQUOTED calls."""
    defines: set[str] = set()

    for match in re.finditer(r"AC_DEFINE(?:_UNQUOTED)?\s*\(\s*\[?(\w+)\]?", text):
        defines.add(match.group(1))

    return defines


def extract_check_headers(text: str) -> set[str]:
    """Extract headers from AC_CHECK_HEADERS and AC_CHECK_HEADER calls."""
    defines: set[str] = set()

    for match in re.finditer(r"AC_CHECK_HEADERS?\s*\(\s*\[([^\]]+)\]", text):
        for header in match.group(1).split():
            header = header.strip().rstrip(",")
            if header:
                defines.add(_header_to_define(header))

    return defines


def extract_check_funcs(text: str) -> set[str]:
    """Extract functions from AC_CHECK_FUNCS calls."""
    defines: set[str] = set()

    for match in re.finditer(r"AC_CHECK_FUNCS\s*\(\s*\[([^\]]+)\]", text):
        for func in match.group(1).split():
            func = func.strip().rstrip(",")
            if func:
                defines.add(_func_to_define(func))

    return defines


def extract_check_types(text: str) -> set[str]:
    """Extract types from AC_CHECK_TYPES and AC_CHECK_TYPE calls."""
    defines: set[str] = set()

    for match in re.finditer(r"AC_CHECK_TYPES?\s*\(\s*\[([^\]]+)\]", text):
        for typename in match.group(1).split(","):
            typename = typename.strip()
            if typename:
                defines.add(_type_to_define(typename))

    return defines


def extract_check_members(text: str) -> set[str]:
    """Extract members from AC_CHECK_MEMBERS calls."""
    defines: set[str] = set()

    for match in re.finditer(r"AC_CHECK_MEMBERS\s*\(\s*\[([^\]]+)\]", text):
        for member in match.group(1).split(","):
            member = member.strip()
            if member:
                defines.add(_member_to_define(member))

    return defines


def extract_func_alloca(text: str) -> set[str]:
    """AC_FUNC_ALLOCA defines HAVE_ALLOCA and HAVE_ALLOCA_H."""
    defines: set[str] = set()
    if re.search(r"AC_FUNC_ALLOCA", text):
        defines.add("HAVE_ALLOCA")
        defines.add("HAVE_ALLOCA_H")
    return defines


def extract_type_uintptr(text: str) -> set[str]:
    """AC_TYPE_UINTPTR_T may define uintptr_t."""
    defines: set[str] = set()
    if re.search(r"AC_TYPE_UINTPTR_T", text):
        defines.add("HAVE_UINTPTR_T")
    return defines


# Symbols that autoconf's standard macros always provide.
_STANDARD_AUTOCONF_DEFINES = {
    "STDC_HEADERS",
    "PACKAGE_NAME",
    "PACKAGE_VERSION",
    "PACKAGE_STRING",
    "PACKAGE_BUGREPORT",
    "PACKAGE_TARNAME",
    "PACKAGE_URL",
    "PACKAGE",
    "VERSION",
}


def extract_source_references(source_dir: Path) -> set[str]:
    """Scan source and test files for config.h symbols used in preprocessor guards.

    Catches defines like HAVE_STDINT_H that are used in #if / #ifdef but
    not explicitly declared in configure.ac (e.g., when they come from
    standard autoconf macros invoked implicitly).
    """
    defines: set[str] = set()
    pattern = re.compile(
        r"(?:#\s*ifn?def\s+|#\s*if\s+(?:defined\s*\(?\s*)?|#\s*elif\s+(?:defined\s*\(?\s*)?)"
        r"(HAVE_\w+|MPFR_\w+|WANT_\w+|NPRINTF_\w+|PRINTF_\w+|DECIMAL_\w+|WORDS_BIGENDIAN|STDC_HEADERS)"
    )
    for subdir in ["src", "tests"]:
        d = source_dir / subdir
        if not d.is_dir():
            continue
        for f in sorted(d.glob("*.[ch]")):
            for match in pattern.finditer(f.read_text(errors="replace")):
                defines.add(match.group(1))
    return defines


def collect_all_defines(source_dir: Path) -> list[str]:
    """Parse all autoconf inputs and return a sorted list of all possible defines."""
    texts: list[str] = []
    for name in ["configure.ac", "acinclude.m4"]:
        path = source_dir / name
        if path.exists():
            texts.append(path.read_text())

    m4_dir = source_dir / "m4"
    if m4_dir.is_dir():
        for m4_file in sorted(m4_dir.glob("*.m4")):
            texts.append(m4_file.read_text())

    combined = "\n".join(texts)

    all_defines: set[str] = set()
    all_defines |= extract_defines(combined)
    all_defines |= extract_check_headers(combined)
    all_defines |= extract_check_funcs(combined)
    all_defines |= extract_check_types(combined)
    all_defines |= extract_check_members(combined)
    all_defines |= extract_func_alloca(combined)
    all_defines |= extract_type_uintptr(combined)
    all_defines |= extract_source_references(source_dir)
    all_defines |= _STANDARD_AUTOCONF_DEFINES

    return sorted(all_defines)


def generate_config_in(defines: list[str]) -> str:
    """Generate the config.in template content."""
    lines = ["/* config.h.  Generated by generate_config_in.py.  */", ""]
    for define in defines:
        lines.append(f"#undef {define}")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    args = parse_args()

    source_dir = args.source_dir.resolve()
    if not (source_dir / "configure.ac").exists():
        raise FileNotFoundError(f"No configure.ac found in {source_dir}")

    version = args.version or parse_version(source_dir)
    defines = collect_all_defines(source_dir)

    out_dir = args.bcr_root / "modules" / "mpfr" / version / "overlay"
    if not out_dir.exists():
        raise FileNotFoundError(f"Overlay directory not found: {out_dir}")

    out_path = out_dir / "config.in"
    content = generate_config_in(defines)
    out_path.write_text(content)

    print(f"Wrote {out_path} ({len(defines)} defines)")


if __name__ == "__main__":
    main()
